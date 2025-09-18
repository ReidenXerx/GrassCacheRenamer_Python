#!/usr/bin/env python3
"""
Seasonal Grass Cache File Renamer
Multithreaded Python version for high performance file renaming
"""

import os
import sys
import glob
import shutil
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
from dataclasses import dataclass
from typing import List, Tuple, Optional
import time
import argparse

@dataclass
class RenameResult:
    """Result of a file rename operation"""
    original_name: str
    target_name: str
    success: bool
    error: Optional[str] = None
    skipped: bool = False

class GrassCacheRenamer:
    """High-performance multithreaded grass cache file renamer"""
    
    SEASONS = {
        '1': ('Winter', '.WIN.cgid'),
        '2': ('Spring', '.SPR.cgid'), 
        '3': ('Summer', '.SUM.cgid'),
        '4': ('Autumn', '.AUT.cgid'),
        '7': ('Remove seasonal extensions', '.cgid')
    }
    
    def __init__(self, target_directory: str = None, max_workers: int = None):
        self.target_directory = target_directory or os.getcwd()
        self._directory_set_via_cmdline = target_directory is not None
        self.max_workers = max_workers or min(32, (os.cpu_count() or 1) + 4)
        self.results = []
        self.lock = threading.Lock()
        
    def display_banner(self):
        """Display the application banner"""
        print("=" * 50)
        print("     S E A S O N A L   G R A S S   C A C H E")
        print("            F I L E   R E N A M E R")
        print("=" * 50)
        print("         Python Multithreaded v3.0")
        print()
        print(f"Target Folder: {self.target_directory}")
        print(f"Max Threads: {self.max_workers}")
        print()
    
    def get_target_directory(self) -> str:
        """Get target directory from user input"""
        print("📁 SELECT TARGET DIRECTORY:")
        print("-" * 50)
        print(f"Current directory: {os.getcwd()}")
        print()
        print("Options:")
        print("  1. Use current directory")
        print("  2. Enter custom path")
        print("  3. Browse with GUI (if available)")
        print("-" * 50)
        
        while True:
            choice = input("Enter your choice (1-3): ").strip()
            
            if choice == '1':
                return os.getcwd()
            elif choice == '2':
                while True:
                    print()
                    path = input("📂 Enter full path to directory: ").strip().strip('"').strip("'")
                    if not path:
                        print("❌ Empty path. Please try again.")
                        continue
                    if os.path.isdir(path):
                        return os.path.abspath(path)
                    else:
                        print(f"❌ Directory '{path}' does not exist. Please try again.")
            elif choice == '3':
                # Try to use tkinter folder dialog
                try:
                    import tkinter as tk
                    from tkinter import filedialog
                    print("\n🔍 Opening folder browser...")
                    root = tk.Tk()
                    root.withdraw()  # Hide main window
                    root.attributes('-topmost', True)  # Bring to front
                    folder_path = filedialog.askdirectory(
                        title="Select folder containing .cgid files",
                        initialdir=os.getcwd()
                    )
                    root.destroy()
                    if folder_path:
                        return os.path.abspath(folder_path)
                    else:
                        print("❌ No folder selected. Please choose again.")
                except ImportError:
                    print("❌ GUI folder browser not available. Please use option 1 or 2.")
                except Exception as e:
                    print(f"❌ Error opening folder browser: {e}")
                    print("Please use option 1 or 2.")
            else:
                print("❌ Invalid choice. Please enter 1, 2, or 3.")
    
    def get_base_filename(self, filename: str) -> str:
        """Extract base filename before first dot (fast string operation)"""
        return filename.split('.')[0]
    
    def get_user_choice(self) -> Tuple[str, str]:
        """Get user's season choice"""
        print("Rename Files to:")
        print("-" * 30)
        for key, (season, _) in self.SEASONS.items():
            print(f"  {key}. {season}")
        print()
        print("  0. Exit without renaming")
        print("-" * 30)
        print()
        
        while True:
            choice = input("Enter your choice: ").strip()
            if choice == '0':
                print("Exiting...")
                sys.exit(0)
            elif choice in self.SEASONS:
                return self.SEASONS[choice]
            else:
                print("Invalid choice, please enter a valid option.")
    
    def find_cgid_files(self, directory: str) -> List[str]:
        """Find all .cgid files in specified directory"""
        pattern = os.path.join(directory, "*.cgid")
        files = glob.glob(pattern)
        return sorted([os.path.basename(f) for f in files])  # Return just filenames, sorted
    
    def rename_single_file(self, filename: str, directory: str, extension: str) -> RenameResult:
        """Rename a single file (thread-safe operation)"""
        try:
            filepath = os.path.join(directory, filename)
            base_name = self.get_base_filename(filename)
            target_name = f"{base_name}{extension}"
            target_path = os.path.join(directory, target_name)
            
            # Check if target already exists
            if os.path.exists(target_path):
                return RenameResult(
                    original_name=filename,
                    target_name=target_name,
                    success=False,
                    error=f"Target file already exists: {target_name}"
                )
            
            # Check if rename is needed
            if filename == target_name:
                return RenameResult(
                    original_name=filename,
                    target_name=target_name,
                    success=True,
                    skipped=True
                )
            
            # Perform atomic rename
            os.rename(filepath, target_path)
            
            return RenameResult(
                original_name=filename,
                target_name=target_name,
                success=True
            )
            
        except Exception as e:
            return RenameResult(
                original_name=filepath,
                target_name="",
                success=False,
                error=str(e)
            )
    
    def process_files(self, files: List[str], directory: str, extension: str) -> None:
        """Process files using multithreading"""
        if not files:
            print(f"No .cgid files found in directory: {directory}")
            return
            
        print(f"Processing {len(files)} files with {self.max_workers} threads...")
        print("=" * 50)
        
        start_time = time.time()
        
        # Use ThreadPoolExecutor for concurrent processing
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            # Submit all tasks
            future_to_file = {
                executor.submit(self.rename_single_file, file, directory, extension): file 
                for file in files
            }
            
            # Process completed tasks
            for future in as_completed(future_to_file):
                result = future.result()
                
                with self.lock:
                    self.results.append(result)
                    
                    # Print immediate feedback
                    if result.success and not result.skipped:
                        print(f"✓ Renamed: {result.original_name} → {result.target_name}")
                    elif result.skipped:
                        print(f"- Skipped: {result.original_name} (already correct)")
                    else:
                        print(f"✗ Error: {result.original_name} - {result.error}")
        
        end_time = time.time()
        self.print_summary(end_time - start_time)
    
    def print_summary(self, duration: float) -> None:
        """Print operation summary"""
        total = len(self.results)
        renamed = sum(1 for r in self.results if r.success and not r.skipped)
        skipped = sum(1 for r in self.results if r.skipped)
        errors = sum(1 for r in self.results if not r.success)
        
        print()
        print("=" * 50)
        print("SUMMARY:")
        print(f"  Total files processed: {total}")
        print(f"  Successfully renamed:  {renamed}")
        print(f"  Already correct name:  {skipped}")
        print(f"  Errors encountered:    {errors}")
        print(f"  Processing time:       {duration:.2f} seconds")
        print(f"  Average time per file: {duration/total*1000:.1f} ms" if total > 0 else "")
        print("=" * 50)
    
    def run(self) -> None:
        """Main application entry point"""
        try:
            self.display_banner()
            
            # Always ask for target directory unless provided via command line
            if not hasattr(self, '_directory_set_via_cmdline') or not self._directory_set_via_cmdline:
                print()
                self.target_directory = self.get_target_directory()
                print(f"\nSelected directory: {self.target_directory}")
                print()
            
            # Find files first to show count
            files = self.find_cgid_files(self.target_directory)
            if not files:
                print(f"No .cgid files found in directory: {self.target_directory}")
                input("Press Enter to exit...")
                return
                
            print(f"Found {len(files)} .cgid files")
            print()
            
            # Get user choice
            season_name, extension = self.get_user_choice()
            
            print()
            print(f"Selected: {season_name}")
            print()
            
            # Process files
            self.process_files(files, self.target_directory, extension)
            
        except KeyboardInterrupt:
            print("\nOperation cancelled by user.")
        except Exception as e:
            print(f"Unexpected error: {e}")
        finally:
            input("Press Enter to exit...")

def parse_arguments():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description="High-performance multithreaded grass cache file renamer",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python renamegrasscache.py
  python renamegrasscache.py --directory "C:\\Games\\Skyrim\\Data"
  python renamegrasscache.py -d "C:\\Path\\To\\Files" --threads 16
        """
    )
    
    parser.add_argument(
        "-d", "--directory",
        help="Target directory containing .cgid files",
        type=str,
        default=None
    )
    
    parser.add_argument(
        "-t", "--threads",
        help="Maximum number of worker threads (default: auto-detect)",
        type=int,
        default=None
    )
    
    parser.add_argument(
        "--version",
        action="version",
        version="Seasonal Grass Cache Renamer v3.0"
    )
    
    return parser.parse_args()

if __name__ == "__main__":
    # Parse command line arguments
    args = parse_arguments()
    
    # Validate directory if provided
    target_dir = None
    if args.directory:
        if os.path.isdir(args.directory):
            target_dir = os.path.abspath(args.directory)
        else:
            print(f"Error: Directory '{args.directory}' does not exist.")
            sys.exit(1)
    
    # Create and run the renamer
    renamer = GrassCacheRenamer(target_directory=target_dir, max_workers=args.threads)
    renamer.run()

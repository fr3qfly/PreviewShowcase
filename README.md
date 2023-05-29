# PreviewShowcase

PreviewShowcase is a command-line tool that updates Swift files containing a `LazyVStack` with previews by generating and adding new previews based on the existing codebase.

## Installation
To use PreviewShowcaseUpdater, follow these steps:

1. Clone the repository to your local machine.
2. Build the project using Swift Package Manager:
```bash
swift build -c release
```
3. Locate the binary file generated after the build process, usually found at .build/release/PreviewShowcaseUpdater.
4. You can either add the binary to your system's $PATH or use the full path to execute the command.

(Or download the executable from the latest release)

## Usage
The tool can be run from the command line as follows:

```bash
previewShowcase <inputFilePath> [--changes-only] [--just-generate] [--indent-space-count <count>] [--search-path <path>] [--excluded-folders <folders>]
```

### Arguments
- `inputFileUrl`: The path to the Swift file that contains the VStack with previews.

### Options
- `--changes-only`: Only search in changed files based to Git status.
- `--just-generate`: Debug flag, used for generating code without updating the input file.
- `--indent-space-count <count>`: Number of spaces for space indentation. **Will generate code with `tab`s if not specified**
- `--search-path <path>`: Search path when searching for all .swift files.
- `--excluded-folders <folders>`: Comma-separated list of folders to be excluded from the search.

## Getting started
1. Create a new SwiftUI View in your project. (The input file)
2. Add a scroll view and an empty `LazyVStack` to the `body`:
```Swift
import SwiftUI

struct ShowcaseView: View {
    
    var body: some View {
        ScrollView {
            LazyVStack {
            }
        }
    }
}
```
3. Run the script:
```bash
previewShowcase <Showcase file path> --search-path <Path of files to search>
```

4. Add any dependencies (`Environment`, `EnvironmentObject`) if needed to input file.

5. (Optional) Add a build script to the project that will automatically add any new previews at the end of the `LazyVStack`
```bash
PreviewShowcaseUpdater <Showcase file path> --changes-only --search-path <Path of files to search>
```

## How It Works

The PreviewShowcaseUpdater tool performs the following steps:

1. Determines the files to search based on whether the `--changesOnly` flag is specified or not.
2. Filters out the excluded folders from the files to search.
3. Reads the content of the input file.
4. Extracts the content of the `LazyVStack`.
5. Identifies the existing preview names in the input file.
6. Retrieves the names of `PreviewProvider`s from the given files.
7. Generates the code for the updated `LazyVStack`.
8. Writes the updated content back to the input file.

The tool supports both space and tab indentation and provides flexibility for code generation based on specific requirements.

## Error Handling

The tool defines a custom error type PreviewShowcaseError with the following case:

`mainStackNotFound`: Indicates that the main VStack could not be found in the input file.
License

This code is released under the **MIT License**.

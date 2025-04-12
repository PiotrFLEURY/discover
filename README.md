## discover

Get your real code coverage

<img 
    src="docs/images/banner.png" 
    alt="discover logo generated using ChatGPT" 
    height="200" />

Discovers helps to find all the Dart sources with no tests. Use Discover to know exactly which Dart files needs to be tested.

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]

Generated by the [Very Good CLI][very_good_cli_link] 🤖

---

## Getting Started 🚀

Activate globally via:

```sh
dart pub global activate discover
```

## Usage

### Perform coverage scan

The scan sub command will search for an existing coverage tracefile and find every source file not listed.

Just run

```sh
# Scan command
$ discover scan

# Scan command option
$ discover scan --path <dart_project_path>
```

If no coverage file exists, Discover will automatically try to generate it using `flutter test --coverage` command.

Untested files will be listed in a `discover-lcov.info` file.

Finally, the HTML report will be generated using both lcov files.

Open the HTML report to Discover your real coverage.

### Tooling commands

```sh
# Show CLI version
$ discover --version

# Show usage help
$ discover --help
```

### Ignore files

You can ignore files by creating a `.discoverignore` file in the root of your project.

```
|-- android
|-- ios
|-- lib
|-- linux
|-- macos
|-- test
|-- windows
|-- .discoverignore
```

Sample `.discoverignore` file:

```
lib/**/*.g.dart
lib/**/*.freezed.dart
lib/view/**/*.dart
```

> 📄 Info 📄
>
> Patterns listed in the `.discoverignore` file will be removed from the original tracefile `lcov.info`

## Local development

Activate locally via:

```sh
dart pub global activate --source=path <path to this package>
```

> 🚨 Note 🚨
>
> An issue prevents from updating the CLI using local path.
>
> If you want to update the CLI, you need to remove `.dart_tool` directory before running the command again.
> See [issue 4295](https://github.com/dart-lang/pub/issues/4295)

### Running Tests with coverage 🧪

To run all unit tests use the following command:

```sh
$ dart pub global activate coverage 1.2.0
$ dart test --coverage=coverage
$ dart pub global run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info
```

To view the generated coverage report you can use [lcov](https://github.com/linux-test-project/lcov)
.

```sh
# Generate Coverage Report
$ genhtml coverage/lcov.info -o coverage/

# Open Coverage Report
$ open coverage/index.html
```

---

[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://github.com/VeryGoodOpenSource/very_good_cli

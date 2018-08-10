# Change Log

All notable changes to this project will be documented in this file.
This project *tries* to adhere to [Semantic Versioning](http://semver.org/), even before v1.0.

## [1.0.7]
- update DYNOMITE_ENV var

## [1.0.6]
- rename to dynomite

## [1.0.5]
- fix jets dynamodb:migrate tip

## [1.0.4]
- Add and use log method instead of puts to write to stderr by default

## [1.0.3]
- rename APP_ROOT to JETS_ROOT

## [1.0.2]
- to_json for json rendering

## [1.0.1]
- Check dynamodb local is running when configured

## [1.0.0]
- LSI support
- automatically infer table_name
- automatically infer create_table and update_table migrations types

## [0.3.0]
- DSL methods now available: create_table, update_table
- Also can add GSI indexes within update_table with: i.gsi

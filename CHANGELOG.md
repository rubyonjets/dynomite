# Change Log

All notable changes to this project will be documented in this file.
This project *tries* to adhere to [Semantic Versioning](http://semver.org/), even before v1.0.

## [1.2.7] - 2022-06-12
- [#23](https://github.com/tongueroo/dynomite/pull/23) #where method refactor to allow Model.index_name('index').where(...)
- [#24](https://github.com/tongueroo/dynomite/pull/24) Add get_endpoint_ip to db_config.rb
- [#26](https://github.com/tongueroo/dynomite/pull/26) change pay_per_use to pay_per_request
- [#27](https://github.com/tongueroo/dynomite/pull/27) Fixed message that tells how to install dynamodb-local

## [1.2.6]
- Implement the `PAY_PER_USE` billing mode for table creations and updates. See [DynamoDB On Demand](https://aws.amazon.com/blogs/aws/amazon-dynamodb-on-demand-no-capacity-planning-and-pay-per-request-pricing/).

## [1.2.5]
- use correct color method

## [1.2.4]
- #16 add rainbow gem dependency for color method
- #17 fix table names for models with namespaces

## [1.2.3]
- #11 fix comments in dsl.rb
- #13 update find method to support composite key

## [1.2.2]
- update Jets.root usage

## [1.2.1]
- #10 from gotchane/fix-readme-about-validation
- #8 from patchkit-net/feature/replace-return-self
- #9 from patchkit-net/feature/custom-errors
- Change Item#replace method to return self
- Add custom Dynomite::Errors::ValidationError and Dynomite::Errors::ReservedWordError
  fixing rspec warnings.

## [1.2.0]
- #7 from patchkit-net/feature/validations
- Add a way to quickly define getters and setters using `column` method
- Can be used with `ActiveModel::Validations`
- Add ActiveModel::Validations (group=test,development) dependency
- Add ActiveModel::Validations Item integration spec
- Add Dynomite::Item.replace and .replace! spec with validations

## [1.1.1]
- #6 from patchkit-net/feature/table-count: add Item.count

## [1.1.0]
- Merge pull request #5 from tongueroo/fix-index-creation
- fix index creation dsl among other things

## [1.0.9]
- allow item.replace(hash) to work
- Merge pull request #3 from mveer99/patch-1 Update comments: Fixed typo in project_name

## [1.0.8]
- scope endpoint option to dynamodb client only vs the entire Aws.config

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

[![Build Status](https://travis-ci.org/UMNLibraries/cdmdexer.svg?branch=master)](https://travis-ci.org/UMNLibraries/cdmdexer)

# CDMDEXER: Index CONTENTdm Content

A micro [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load) system dedicated to extracting metadata records from a CONTENTdm instance (using the [CONTENTdm API gem](https://github.com/UMNLibraries/contentdm_api), transforming them into Solr documents, and loading them into Solr.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cdmdexer'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cdmdexer

Run the cdmdexer install generator. This step will add a `config/settings.yml` file to your local application, containing default Solr field mappings and formatters to your project:

    $ bundle exec rails g cdmdexer:install

Add the CDMDEXER rake task to your project Rakefile:

```ruby
require 'cdmdexer/rake_task'
```

### GeoNames (optional)

In order to make use of the GeoNames service, you must purchase a [GeoNames Premium Webservices Account](http://www.geonames.org/commercial-webservices.html). If you do not have a `geonam` field in your CONTENTdm schema, you may ignore this instruction. Add your credentials to your shell environment once you have secured a GeoNames user:


```
cp .env.example .env
nano .env

# Add these vars to the .env file
GEONAMES_USER=foo
GEONAMES_TOKEN=bar
```

## Usage

Run the ingester

rake cdmdexer:batch[solr_url,oai_endpoint,cdm_endpoint,set_spec, batch_size, max_compounds]

|Argument| Definition|
|--:|---|
|solr_url| The full URL to your Solr core instance (same as your blacklight.yml solr url)|
|oai_endpoint| A URL to your OAI instance (e.g. https://server16022.contentdm.oclc.org/oai/oai.php)   |
|cdm_endpoint| A URL to your CONTENTdm API endpoint (e.g. https://server16022.contentdm.oclc.org/dmwebservices/index.php) |
|set_spec| Selectively harvest from a single collection with [setSpec](http://www.openarchives.org/OAI/openarchivesprotocol.html#Set)|
|batch_size| The number of records to transform at a time. **Note**: it is within the record transformation process that the CONTENTdm API is requested. This API can be sluggish, so we conservatively transform batches of ten records at a time to prevent timeouts.|
|max_compounds| CONTENTdm records with many compounds can take a long time to load from the CONTENTdm API as multiple requests must happen in order to get the metadata for each child record of a parent compound object. For this reason, records with ten or more compound children are, by default, processed in batches of one. This setting allows you to override this behavior.|

For example:

```ruby
rake "cdmdexer:ingest[http://solr:8983/solr/foo-bar-core, https://server16022.contentdm.oclc.org/oai/oai.php, https://server16022.contentdm.oclc.org/dmwebservices/index.php, 2015-01-01]"
```

### Custom Rake Tasks

You might also create your own rake task to run your modified field transformers:

```ruby
require 'cdmdexer'

namespace :cdmdexer do
  desc "ingest batches of records"
  ##
  # e.g. rake mdl_ingester:ingest[2015-09-14, 2]
  task :batch, [:batch_size, :set_spec] => :environment  do |t, args|
    config  =
      {
        oai_endpoint: 'http://cdm16022.contentdm.oclc.org/oai/oai.php',
        cdm_endpoint: 'https://server16022.contentdm.oclc.org/dmwebservices/index.php',
        set_spec: (args[:set_spec] != '""') ? args[:set_spec] : nil,
        batch_size: (args[:batch_size]) ? args[:batch_size] : 30,
        solr_config: solr_config
      }
    CDMDEXER::ETLWorker.perform_async(config)
  end
end
```
### Your Own Custom Solr Field Mappings (see above code snippet)

The default CONTENTdm to Solr field transformation rules may be overriden by calling the CDMDEXER::ETLWorker (a [Sidekiq worker](https://github.com/mperham/sidekiq)) directly. These rules may be found in the default_mappings method of the [CDMDEXER::Transformer Class](https://github.com/UMNLibraries/cdmdexer/blob/master/lib/cdmdexer/transformer.rb).

The transformer expects mappings in the following format:

```ruby
def your_custom_field_mappings
  [
    {dest_path: 'title_tei', origin_path: 'title', formatters: [StripFormatter]},
  ]
end
```
|Argument| Definition|
|--:|---|
|dest_path| The 'destination path' is the name of the field you will be sending to Solr for this field mapping. |
|origin_path| Where to get the field data from the original record for this mapping. |
|formatters| [Formatters](https://github.com/UMNLibraries/cdmdexer/blob/master/lib/cdmdexer/formatters.rb) perform tasks such as stripping white space or splitting CONTENTdm multi-valued fields (delimited by semicolons) into JSON arrays. |

**Note:** The first formatter receives the value found at the declared `origin_path`. Each formatter declared after the initial formatter will receive a value produced by the preceding formatter.

Formatters are very simple stateless classes that take a value, do something to it, and respond with a modified version of this value via a class method called `format`. Examples of other formatters may be found in the [Formatters file](https://github.com/UMNLibraries/cdmdexer/blob/master/lib/cdmdexer/formatters.rb). For Example:

```ruby
  class SplitFormatter
    def self.format(value)
      (value.respond_to?(:split)) ? value.split(';') : value
    end
  end
```

You might also want to simply override some of the default mappings or add your own:

```ruby
mappings = CDMDEXER::Transformer.default_mappings.merge(your_custom_field_mappings)
```

### Callbacks

CDMDEXER comes with a set of lifecycle hooks that are called at various points during the ETL process. Downstream applications may want to take advantage of these in order to perform logging or notification tasks.  Create a Rails initializer at `config/initializers/cdmdexer.rb` in order to take advantage of these hooks.

**IMPORTANT NOTE:**  Errors (except for http timeouts) are **not raised** but are rather sent to the `CdmError` notification hook below. This prevents sidekiq from piling-up with errors that will never resolve via retries but still allows you to capture the error and be notified of error events.

E.g.:

```ruby
module CDMDEXER
  class CompletedCallback
    def self.call!(config)
      # e.g. commit records  - ::SolrClient.new.commit
      Rails.logger.info "Processing last batch for: #{config['set_spec']}"
    end
  end

  class OaiNotification
    def self.call!(location)
      Rails.logger.info "CDMDEXER: Requesting: #{location}"
    end
  end

  class CdmNotification
    def self.call!(collection, id, endpoint)
      Rails.logger.info "CDMDEXER: Requesting: #{collection}:#{id}"
    end
  end

  class LoaderNotification
    def self.call!(ingestables, deletables)
      Rails.logger.info "CDMDEXER: Loading #{ingestables.length} records and deleting #{deletables.length}"
    end
  end

  class CdmError
    def self.call!(error)
      Rails.logger.info "CDMDEXER: #{error}"
      # e.g. push error to a slack channel or send an email alert
    end
  end
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/UMNLibraries/cdmdexer. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

[MIT](/LICENSE.txt)

## TODO

* Make StripFormatter the default formatter so it doesn't need to be declared for every field
* Re-brand project: CONTENTdm Indexer. CDMDEXER doesn't necessarily require Blacklight. Moreover only handles indexing.

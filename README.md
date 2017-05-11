Amazon Web Services Pricing Ruby Gem
====================================

[![Test Report](https://ci.solanolabs.com/cloudhealthtech/amazon-pricing/badges/branches/master)](https://ci.solanolabs.com/cloudhealthtech/amazon-pricing/suites/48198)
[![Gem Version](https://badge.fury.io/rb/amazon-pricing.svg)](http://badge.fury.io/rb/amazon-pricing)
[![Code Climate](https://codeclimate.com/github/CloudHealth/amazon-pricing/badges/gpa.svg)](https://codeclimate.com/github/CloudHealth/amazon-pricing)
[![Coverage Status](https://coveralls.io/repos/github/CloudHealth/amazon-pricing/badge.svg?branch=master)](https://coveralls.io/github/CloudHealth/amazon-pricing?branch=master)

About amazon-pricing
--------------------

Amazon Web Services offers cloud-based on demand compute, storage and application services. Due to the number of services, and the number of pricing variables in each service, the pricing model is very complex. In addition, this pricing changes periodically. The amazon-pricing Ruby Gem is an interface library that simplifies the real-time retrieval of pricing information from Amazon.

For the most complete and up-to date README information please visit the project homepage at:

http://github.com/CloudHealth/amazon-pricing/tree/master

Installation
------------

This gem follows the standard conventions for installation on any system with Ruby and RubyGems installed and uses Bundler for gem installation and build management.

### Get an AWS account

Before you can make use of this gem you will need an Amazon Web Services account.

### Install the amazon-pricing gem (Canonical Release)

This is the standard install for stable releases from RubyGems.

* Install the gem: `[sudo] gem install amazon-pricing`

### Install from local Git clone (for amazon-pricing developers)

To install from git for adding features or fixing bugs, you'll need to clone and build.

```
git clone git://github.com/CloudHealth/amazon-pricing.git
cd amazon-pricing
bundle install
rake test
rake build
rake install
```

Using amazon-pricing
--------------------

The library exposes one main interface class AwsPricing::PriceList that allows you to retrieve pricing information from Amazon. The information is retrieved using undocumented json APIs - so has the potential to undergo change from time to time.

The following article provides a good introduction to using the gem:

http://www.hightechinthehub.com/2012/03/programmatically-retrieving-aws-pricing/

### The Basics

The library exposes one main interface module

```
AwsPricing::PriceList
```

Additional Resources
--------------------

### Project Websites

* Project Home : http://github.com/CloudHealth/amazon-pricing/tree/master
* API Documentation : http://rdoc.info/projects/CloudHealth/amazon-pricing
* Report Bugs / Request Features : http://github.com/CloudHealth/amazon-pricing/issues
* Amazon Web Services : http://aws.amazon.com

Credits
-------

Thanks for Amazon developers for provided JSON APIs to the pricing data (albeit undocumented).

Contact
-------

Comments, patches, Git pull requests and bug reports are welcome. Send an email to mailto:joe.kinsella@gmail.com.

Patches & Pull Requests
-----------------------

Please follow these steps if you want to send a patch or a GitHub pull request:

* Fork CloudHealth/amazon-pricing
* Create a topic branch: `git checkout -b my_fix`
* Make sure you add tests for your changes and that they all pass with 'rake test'
* Don't change files that you don't own like the gemspec or version.rb
* Commit your changes, one change/fix per commit
* Push your fixes branch: `git push origin my_fix`
* Open an Issue on GitHub referencing your branch and send a pull request.
* Please do not push to `master` on your fork. Using a feature/bugfix branch will make everyone’s life easier.

Enjoy!

CloudHealth

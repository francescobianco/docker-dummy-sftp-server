# -*- mode: ruby -*-
# vi: set ft=ruby :

source 'https://rubygems.org'

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'dockerspec', '~> 0.5.0'

# You should_not start your specs with the string "should"
gem 'should_not', '~> 1.1'

# Use our forked version of docker-compose-api
# TODO: This can be removed after https://github.com/mauricioklein/docker-compose-api/pull/50
# gets merged
gem "docker-compose-api", github: 'onnimonni/docker-compose-api'

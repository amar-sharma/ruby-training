clone this repo
cd KeyServer
bundle install

Run server using:
bundle exec ruby server.rb

Test
bundle exec rspec -fd

Test handler
bundle exec rspec -fd -t helper

Test server
bundle exec rspec -fd -t server


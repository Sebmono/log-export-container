require 'fluent/plugin/parser'
require 'fluent/plugin/parser_json'

# Remove characters before JSON from SDM log lines, format:
# 2021-06-22T17:15:19Z ip-172-31-3-25 strongDM[734548]: {\"type\":\"complete\",\"timestamp\":\"2021-06-22T17:15:19.758785454Z\",\"uuid\":\"01uJSIaxJKEf6y85VRAoypiPJUGJ\",\"duration\":0,\"records\":1}
module Fluent::Plugin
  class SDMJsonParser < Parser
    Fluent::Plugin.register_parser('sdm_json', self)

    def configure(conf)
      super
      @parser = Fluent::Plugin::JSONParser.new
      @parser.configure(Fluent::Config::Element.new('ROOT', '', {}, []))
    end

    def parse(text)
      record = text.gsub(/^.*: /, '')
      @parser.parse(record) { 
        |_, r| record = r
      }
      yield Fluent::EventTime.now, record
    end
  end
end
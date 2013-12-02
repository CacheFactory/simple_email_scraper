#!/usr/bin/env ruby
require "open-uri"
require 'rubygems' 
require 'bundler/setup'  # require your gems as usual require 'nokogiri'
require 'httparty'

class EmailFinder
  DEEPNESS=3
  EMAIL_REGEX =/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
  HREF_REXEX = /href="([^"]*)"/

  def self.download_email_addresses_from_url url
    uri = URI url
    results = self.parse_page_for_emails uri
    results.each do |key,email|
      puts "#{email[:email]} #{email[:uri]}"
    end
  end

  private

    def self.parse_page_for_emails uri, emails={}, hrefs=[], deepness=0
    #puts uri.to_s
      html =HTTParty.get uri.to_s
    #puts html
      html.scan(EmailFinder::EMAIL_REGEX).each do |email_match|
        emails[email_match] = {:email => email_match, :uri => uri.to_s } 
      end

      html.scan(EmailFinder::HREF_REXEX).each do |href_match_array|
        href_match= href_match_array[0]
  
        href_match ="#{uri.scheme}://#{uri.host}#{href_match}" if  href_match[0,1]=='/'
        new_uri = URI href_match
        if !hrefs.include?(href_match) && uri.host  == new_uri.host && deepness <= EmailFinder::DEEPNESS
          begin
            hrefs << href_match
            self.parse_page_for_emails new_uri, emails, hrefs, deepness+1
            
          rescue
            
          end
        end
      end
      return emails

    end
end 

EmailFinder.download_email_addresses_from_url ARGV.first
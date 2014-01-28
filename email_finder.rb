#!/usr/bin/env ruby
require "open-uri"
require 'rubygems' 
require 'bundler/setup'  # require your gems as usual require 'nokogiri'
require 'httparty'
require 'nokogiri'
require 'pry'

class EmailFinder
  DEEPNESS=4
  EMAIL_REGEX =/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
  #HREF_REXEX = /href="([^"]*)"/

  def self.download_email_addresses_from_url url
    uri = URI url
    results = self.parse_page_for_emails uri
   
    results.each do |key,email|
      puts "#{email[:email]} #{email[:uri]}"
    end

  end

  private

    def self.parse_page_for_emails uri, emails={}, hrefs=[], deepness=0
      html =HTTParty.get uri.to_s

      doc = Nokogiri::HTML(html)
      
      html.scan(EmailFinder::EMAIL_REGEX).each do |email_match|
        emails[email_match] = {:email => email_match, :uri => uri.to_s } 
      end

      doc.search('a').each do |element|
        href_match= element.attributes['href'].value
  
        if href_match[0,1]=='/'
          new_path ="#{uri.scheme}://#{uri.host}/#{href_match}" 
        elsif !href_match.match('http') 

          folder_array = uri.path.split('/')
          folder_array.pop
          folder=folder_array.join('/')

          new_path ="#{uri.scheme}://#{uri.host}#{folder}/#{href_match}"
        else
          new_path=href_match
        end


        new_uri = URI new_path
        if !hrefs.include?(href_match) && uri.host  == new_uri.host && deepness < EmailFinder::DEEPNESS
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
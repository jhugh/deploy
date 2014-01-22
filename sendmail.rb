#!/usr/bin/ruby

## SEND EMAIL VIA GMAIL

require 'net/smtp'
require 'date'
require 'time'

@time = Time.now.asctime

## SET UP CONNECTION PARAMS
username = "#{ARGV[0]}"
pass = "#{ARGV[1]}"
domain = "gmail.com"

## CREATE MESSAGE
from = username
to = from
message = <<END_OF_MESSAGE
From: #{from} 
To: #{to}
Subject: #{ARGV[2]}
#{ARGV[3]}
[sent at #{@time} ]
END_OF_MESSAGE

## SEND MESSAGE
smtp = Net::SMTP.new('smtp.gmail.com', 587 )
smtp.enable_starttls
smtp.start(domain, username, pass, :login) do |smtp|
        smtp.send_message message, from, to
end

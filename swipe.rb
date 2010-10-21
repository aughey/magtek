require 'usb'
require 'cgi'

device = USB.devices.find{|u| u.idProduct == 0x0002 && u.idVendor == 0x0801}

interface = device.interfaces.first

endpoint = interface.endpoints.first

handle = device.open

handle.usb_detach_kernel_driver_np(0,0) rescue nil

# handle.set_configuration(1)

handle.usb_claim_interface(0)

loop do
  puts "Paddle Number: "
  paddle = STDIN.gets.chomp

  # Clear out any pending swipes
  loop do
    begin
      size = handle.usb_interrupt_read(0x81,data,-1)
    rescue
      break
    end
  end

  puts "Please Swipe..."

  data = (0..1024).to_a.pack("c*")
  size = handle.usb_interrupt_read(0x81,data,0)


  track1_status,track2_status,track3_status,track1_len,track2_len,track3_len,type,track1_data,track2_data,track3_data = data.unpack("CCCCCCCa109a109a109")
  puts track1_data
  puts track2_data
  puts track3_data

  match = /^%B(.*)\^(.*)\^(..)(..)(...)(.*)\?/.match(track1_data)
  next unless match
  cardnum,name,yy,mm,service_code,extra = match.captures

  puts "Card Number: #{cardnum}"
  puts "Name: #{name}"
  puts "Exp: #{mm}/#{yy}"
  puts "Service Code: #{service_code}"
  puts "Extra Data: #{extra}"

  exp = "#{mm}/#{yy}"
  #"?swipe[track3_data]=#{CGI.escape(track3_data)}&swipe[track2_data]=#{CGI.escape(track2_data)}&swipe[track1_data]=#{CGI.escape(track1_data)}&swipe[number]=#{CGI.escape(cardnum)}&swipe[name]=#{CGI.escape(name)}&swipe[exp]=#{CGI.escape(exp)}&swipe[service_code]=#{CGI.escape(service_code)}&swipe[extra]=#{CGI.escape(extra)}"
  postdata = "?paddle=#{CGI.escape(paddle)}&swipe[number]=#{CGI.escape(cardnum)}&swipe[name]=#{CGI.escape(name)}&swipe[exp]=#{CGI.escape(exp)}&swipe[service_code]=#{CGI.escape(service_code)}&swipe[extra]=#{CGI.escape(extra)}"

  command = ARGV.clone
  command << '"' + command.pop + postdata + '"'

  system command.flatten.join(' ')
end

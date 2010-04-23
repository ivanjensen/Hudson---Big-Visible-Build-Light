#!/usr/bin/ruby 

require 'rubygems'
require 'json'
require 'net/http'
require "serialport"

class BuildStats
  @total
  @failedCount

  def initialize
    @total = 0
    @failedCount = 0
  end

  def addBuild
    @total += 1
  end
    
  def addFail
    @failedCount += 1
  end

  def getBuildColor()
  	if @total == 0
  		[255.chr, 0.chr, 255.chr]
  	else 
  		goodnessPercentage = 100 - (100 / @total * @failedCount)
  		if goodnessPercentage == 100
  			[0.chr, 255.chr, 0.chr]
  		else
  		  [255.chr, 0.chr, 0.chr]
  		end
  	end
  end
end

class HudsonViewPage
  @http
  @url
  
  def initialize(host, url, port = 80)
    @http = Net::HTTP.new(host, port)
    @url = fixupUrl(url)
  end
  
  def fixupUrl(url) 
    if (url !=~ /^\//)  # Ensure there's a slash at the start
      url = '/' + url
    end
    if (url !=~ /\/$/)  # Ensure there's a slash at the end
      url = url + '/'
    end
    if (url !=~ /api\/json\/*/)  # Ensure we're calling the json api
      url = url + 'api/json'
    end
    url
  end
  
  def getBuildStats()
  	response, data = @http.get(@url)

  	document = JSON.parse(data)

    buildStats = BuildStats.new();
  	document["jobs"].each { |it|
  		if it['color'] != 'disabled'
  			buildStats.addBuild()
  			if !(it['color']  == 'blue' or it['color'] == 'blue_anime')
  				buildStats.addFail()
  			end
  		end
  	}
  	buildStats
  end
end


host, url, port = ARGV

viewPage = HudsonViewPage.new(host, url, port)  

#params for serial port
port_str = "/dev/tty.usbserial-A8008Ko5"  #may be different for you
baud_rate = 9600
data_bits = 8
stop_bits = 1
parity = SerialPort::NONE


sp = SerialPort.new(port_str, baud_rate, data_bits, stop_bits, parity)

while true
  buildStats = viewPage.getBuildStats()
  sp.write "#" + 1.chr + buildStats.getBuildColor().to_s
  sleep(10)
end

sp.close()

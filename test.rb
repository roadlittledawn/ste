require 'json'
require 'net/http'

url = URI.parse('http://localhost:9292/users/org/22')
req = Net::HTTP::Get.new(url.to_s)
res = Net::HTTP.start(url.host, url.port) {|http|
  http.request(req)
}
a = JSON.parse(res.body)
# puts a.to_h

# if a.include?( 'pages' )
#     puts 'Pages found'
# else
#     puts a
# end

h = {}
h = {"a" => [["b","e"]]}
# p h                         # => {"a"=>[["b", "e"]]}
h["a"] << ["d", "f"]
# p h                         # => {"a"=>[["b", "e"], ["d", "f"]]}



puts JSON.generate(h)
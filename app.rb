require 'json'

# accounts_file = File.read('mock_db/accounts.json')
# orgs_file = File.read('mock_db/orgs.json')
# users_file = File.read('mock_db/users.json')

# accounts_arr = JSON.parse(accounts_file)
# orgs_arr =JSON.parse(orgs_file)
# users_arr = JSON.parse(users_file)

# mrg = []
# accounts_arr.each do |el1|
#   orgs_arr.each do |el2|
#     if el2['id'] == el1['org_id']
#       mrg.push(el1.merge(el2))
#     end
#   end
# end

# IO.write('app_json.txt', mrg)
# p mrg

require 'net/http'

def get_json(resource)
    url = URI.parse(resource)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    # need to ensure we get result and if not return nil
    if res.code == 404
        return nil
    else
        arr = JSON.parse(res.body)
        if arr["pages"]
            # we already have page 1 results so start at page 2
            i = 2
            pages = arr["pages"]
            while i <= pages  do
                url = URI.parse(resource.to_s+"?page="+i.to_s)
                req = Net::HTTP::Get.new(url.to_s)
                res = Net::HTTP.start(url.host, url.port) {|http|
                  http.request(req)
                }
                if res.code == 404
                    return nil
                else
                    res_json = JSON.parse(res.body)
                    arr["results"] += res_json["results"]
                end
                i += 1
            end
            return arr["results"]
        else 
            return arr
        end
    end
end

orgs_ids_arr = get_json('http://localhost:9292/orgs')
accounts_ids_arr = get_json('http://localhost:9292/accounts')
accounts_objects = []
accounts_ids_arr.each do |acct_id|
    accounts_objects += get_json("http://localhost:9292/accounts/#{acct_id}").to_a
end

orgs_arr = []
orgs_ids_arr.each do |org_id|
    # puts get_json("http://localhost:9292/orgs/#{org}")
    orgs_arr_item = get_json("http://localhost:9292/orgs/#{org_id}")
    org_accounts = []
    accounts_objects.each do |acct_obj|
        if acct_obj["org_id"] == orgs_arr_item["id"]
            org_accounts << acct_obj
        end
    end
    # orgs_arr += orgs_arr_item.to_a
end
# puts orgs_arr.to_json
# puts orgs_arr
# mrg = []
# accounts_arr.each do |acct|
#   orgs_arr.each do |org|
#     if org["id"] == acct["org_id"]
#       mrg.push(acct.merge(org))
#     end
#   end
# end




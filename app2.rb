require 'json'
require 'net/http'

def get_json(resource)
    url = URI.parse(resource)
    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }
    # need to ensure we get result and if not return nil
    if res.code == 404
        return ""
    # elsif res.body
    else
        arr = JSON.parse(res.body)
        if arr.include?('pages')
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
                    return ""
                else
                    res_json = JSON.parse(res.body)
                    arr["results"] += res_json["results"]
                end
                i += 1
            end
            return arr["results"]
        else 
            return arr.to_a
        end
    end
end

def get_orgs_ids
    $orgs_ids_arr = get_json('http://localhost:9292/orgs')
    return $orgs_ids_arr
end

def get_org_obj (org_id)
    orgs_arr_item = get_json("http://localhost:9292/orgs/#{org_id}")
    return orgs_arr_item
end

def get_all_org_arr_obj
    $all_org_arr_obj = []
    get_orgs_ids.each do |id|
        org_arr = get_org_obj (id)
        $all_org_arr_obj << org_arr
    end
    return $all_org_arr_obj
end
# Call function to store all org objects.
# global: $all_org_arr_obj
#
get_all_org_arr_obj

def get_accounts_ids
    $accts_ids_arr = get_json('http://localhost:9292/accounts')
    return $accts_ids_arr
end

def get_acct_obj (acct_id)
    acct_arr_item = get_json("http://localhost:9292/accounts/#{acct_id}")
    return acct_arr_item
end

def get_all_acct_arr_obj
    $all_acct_arr_obj = []
    get_accounts_ids.each do |id|
        acct_arr = get_acct_obj (id)
        $all_acct_arr_obj << acct_arr
    end
    return $all_acct_arr_obj
end
# Call function to store all account objects. 
# global: $all_acct_arr_obj
#
get_all_acct_arr_obj

def get_all_user_ids
    $users_ids_arr = get_json('http://localhost:9292/users')
    return $users_ids_arr
end
# Call function to store all account objects. 
# global: $all_acct_arr_obj
#
get_all_user_ids

def get_user_obj (user_id)
    user_obj = get_json("http://localhost:9292/users/#{user_id}")
    return user_obj
end

def get_user_ids_by_org (org_id)
    user_obj = get_json("http://localhost:9292/users/org/#{org_id}")
    return user_obj
end

def get_admin_user_ids_by_org (org_id)
    user_obj = get_json("http://localhost:9292/users/org/#{org_id}/admin")
    return user_obj
end

def get_org_owners (org_id)
end

def get_org_contacts (org_id)
end

def get_org_users_obj_by_role (org_id, role)
    if role == 'admin'
        user_ids = get_json("http://localhost:9292/users/org/#{org_id}/admin")
        # separate loop?
    elsif role == 'contact' or role == 'owner'
        user_ids = get_user_ids_by_org (org_id)
    end

    user_ids = get_user_ids_by_org (org_id)
    user_obj_arr = []
    user_ids.each do |user_id|
        user_obj = get_user_obj (user_id)
        if user_obj[4][1] == role
            user_obj_arr << user_obj
        end
    end

    return user_obj_arr
end

def get_org_accts_obj (org_id)
    org_acct_arr = []
    $all_acct_arr_obj.each do |acct_obj|
        # puts "Acct object org id: #{acct_obj[0][1]} Org id: #{org_id}"
        # puts acct_obj.inspect
        if acct_obj[1][1] == org_id
            # puts acct_obj.inspect
            org_acct_arr << acct_obj
        end
    end
    return org_acct_arr
end

def get_org_children (org_id)
    # get all org objects first
    org_children = []
    $all_org_arr_obj.each do |org|
        if org[2][1] == org_id
            org_children << org
        end
    end
    return org_children
end

def calc_support_score (revenue)
    if revenue == nil
        return 0
    elsif revenue.between?(0,50000)
        return 1
    elsif revenue.between?(50001,100000)
        return 2
    elsif revenue.between?(100001,150000)
        return 3
    elsif revenue.between?(150001,200000)
        return 4
    elsif revenue.between?(200001,250000)
        return 5
    elsif revenue.between?(250001,300000)
        return 6
    end
end

output_arr = []

$all_org_arr_obj.each do |org_obj|


    this_org_id = org_obj[0][1]
    # Get this org's accounts data
    this_org_accts_obj = get_org_accts_obj (this_org_id)

    # Set up revenue data for this org and its children's org's revenue
    revenue_arr = {}
    acct_revenue = []
    # Collect all account IDs
    acct_ids = ['account_ids']
    this_org_accts_obj.each do |this_org_acct|
        acct_revenue << this_org_acct[2][1]
        acct_ids << this_org_acct[0][1]
    end
    revenue_arr['own_revenue'] = acct_revenue.inject(0){|sum,x| sum + x }
    revenue_arr['own_support_score'] = calc_support_score (revenue_arr['own_revenue'])

    # Set up user data
    users = {}
    # Get this org's account admin users
    admin_user_ids = get_admin_user_ids_by_org (this_org_id)
    admin_user_objs = []
    admin_user_ids.each do |admin_id|
        admin_user_obj = get_user_obj (admin_id)
        admin_user_objs << admin_user_obj
    end
    users['account_admins'] = admin_user_objs

    users['org_owners'] = get_org_users_obj_by_role this_org_id, "owner"
    users['org_contacts'] = get_org_users_obj_by_role this_org_id, "contact"

    org_obj << users.to_a

    # Now get this org's children orgs' account data
    org_children = get_org_children (this_org_id)
    child_acct_revenue = []
    org_children.each do |child_org|
        $all_acct_arr_obj.each do |acct_obj|
            if child_org[0][1] == acct_obj[1][1]
              child_acct_revenue  << acct_obj[2][1]
            end
        end
    end
    revenue_arr['children_revenue']= child_acct_revenue.inject(0){|sum,x| sum + x }
    revenue_arr['children_support_score'] = calc_support_score (revenue_arr['children_revenue'])
    org_obj << revenue_arr.to_a
    org_obj << acct_ids

    
    output_arr << org_obj



end

s = output_arr.to_h
puts s.to_json
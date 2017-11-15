require 'sinatra'
require 'json'
require 'rack/throttle'
require 'multi_json'

%w[lib].each { |dir| Dir.glob("./#{dir}/*.rb", &method(:require)) }

class DB
  def initialize
    @orgs = load_orgs
    @org_ids = (1..@orgs.length).to_a.shuffle
    @accounts = load_accounts
    @account_ids = (1..@accounts.length).to_a.shuffle
    @users = load_users
    @user_ids = (1..@users.length).to_a.shuffle
  end

  def get_orgs(page)
    get_page(page, @org_ids)
  end

  def get_org_by_id(id)
    @orgs[id]
  end

  def get_accounts(page)
    get_page(page, @account_ids)
  end

  def get_account_by_id(id)
    return nil unless @account_ids.include?(id)
    @accounts[id-1]
  end

  def get_account_by_org_id(id)
    return nil unless @org_ids.include?(id)
    @accounts.map { |a| a['id'] if a['org_id'] == id }.compact
  end

  def get_users(page)
    get_page(page, @user_ids)
  end

  def get_users_by_id(id)
    return nil unless @user_ids.include?(id)
    @users[id-1]
  end

  def get_users_by_org(id)
    return nil unless @orgs.key?(id.to_i)
    @users.map { |u| u['id'] if u['org_id'] == id.to_i }.compact
  end

  def get_admin_users_by_account(id)
    return nil unless @org_ids.include?(id)
    @users.map do |u|
      next unless u['role'] == 'admin'
      u['id'] if u['org_id'] == id
    end
  end

  private

  def get_page(page, object)
    pages = (object.length / 10)
    return nil if page.negative? || page > pages
    { results: object[((page-1) * 10)..(page*10)-1],
      page: page,
      pages: pages }
  end

  def load_orgs
    f = File.read('mock_db/orgs.json')
    orgs = JSON.parse(f)
    orgs.each_with_object({}) do |org, memo|
      memo[org['id']] = org
    end
  end

  def load_accounts
    f = File.read('mock_db/accounts.json')
    JSON.parse(f)
  end

  def load_users
    f = File.read('mock_db/users.json')
    JSON.parse(f)
  end
end

class MockApi < Sinatra::Application
  db = DB.new
  use Rack::Throttle::Minute, max: 30, message: 'Rate Limit Exceeded: 30 cpm'

  before do
    verify
    halt 503, 'service unavailable' if rand(100) < 4
  end

  get '/orgs' do
    page = params[:page]&.to_i || 1
    results = db.get_orgs(page)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/orgs/:id' do
    results = db.get_org_by_id(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/accounts' do
    page = params[:page]&.to_i || 1
    results = db.get_accounts(page)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/accounts/:id' do
    results = db.get_account_by_id(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/accounts/org/:id' do
    results = db.get_account_by_org_id(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/users' do
    page = params[:page]&.to_i || 1
    results = db.get_users(page)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/users/:id' do
    results = db.get_users_by_id(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/users/org/:id' do
    results = db.get_users_by_org(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.to_json
  end

  get '/users/org/:id/admin' do
    results = db.get_admin_users_by_account(params[:id].to_i)
    halt 404, 'not found' if results.nil?
    results.compact.to_json
  end
end

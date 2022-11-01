require 'sinatra'
require 'ostruct'
Dir["./lib/shopping_app/*.rb"].each {|file| require file }

get '/' do
  reset

  init_shop

  erb :welcome
end

post '/register' do
  init_customer(params[:name], params[:deposit_amount])

  redirect '/shop'
end

get '/shop' do
  redirect ?/ and return unless @customer = customer

  @cart_items = @customer.cart.items || []
  @customer_items = @customer.items
  @seller = seller
  @seller_items = @seller.items

  erb :shop
end

post '/add-to-cart' do
  redirect ?/ and return unless @customer = customer

  items_by_name = seller.items.group_by(&:name)
  item = items_by_name[params[:name]].last
  redirect ?/ and return unless item

  @customer.cart.add(item)

  is_over_stock_size = @customer.cart.items.group_by(&:name)[params[:name]].size > items_by_name[params[:name]].size
  is_over_my_balance = @customer.cart.total_amount > @customer.wallet.balance
  @customer.cart.items.delete(item) if is_over_stock_size || is_over_my_balance

  File.write("./db/customer.txt", Marshal.dump(@customer))

  redirect '/shop'
end

post '/deposit' do
  redirect ?/ and return unless @customer = customer
  
  @customer.wallet.deposit(params[:balance].to_i)

  File.write("./db/customer.txt", Marshal.dump(@customer))

  redirect '/shop'
end

post '/check-out' do
  redirect ?/ and return unless @customer = customer

  seller = seller()
  my_items = @customer.cart.items.map do |item|
    seller.wallet.deposit(@customer.wallet.withdraw(item.price))
    item.owner = @customer

    File.write("./db/seller.txt", Marshal.dump(seller))

    item
  end

  seller_items_by_name = seller.items.group_by(&:name)

  my_items.group_by(&:name).each do |name, items|
    seller_items_by_name[name][0..(items.size - 1)] = items
  end
  
  items = seller_items_by_name.values.flatten + @customer.items
  File.write("./db/items.txt", Marshal.dump(items))

  @customer.cart.items.clear
  File.write("./db/customer.txt", Marshal.dump(@customer))

  redirect '/shop'
end

private

def reset
  Dir["./db/*.txt"].each { |file_path| File.write(file_path, "") }
end

def init_shop
  seller

  seller = Seller.new("DICストア")

  items = [
            *10.times.map{ Item.new("CPU", 40830, seller) },
            *10.times.map{ Item.new("メモリー", 13880, seller) },
            *10.times.map{ Item.new("マザーボード", 28980, seller) },
            *10.times.map{ Item.new("電源ユニット", 8980, seller) },
            *10.times.map{ Item.new("PCケース", 8727, seller) },
            *10.times.map{ Item.new("3.5インチHDD", 10980, seller) },
            *10.times.map{ Item.new("2.5インチSSD", 13370, seller) },
            *10.times.map{ Item.new("M.2 SSD", 12980, seller) },
            *10.times.map{ Item.new("CPUクーラー", 13400, seller) },
            *10.times.map{ Item.new("グラフィックボード", 23800, seller) },
          ].flatten

  File.write("./db/seller.txt", Marshal.dump(seller))
  File.write("./db/items.txt", Marshal.dump(items))
end

def init_customer(name, deposit_amount = 0)
  customer = Customer.new(name)
  customer.wallet.deposit(deposit_amount.to_i)

  File.write("./db/customer.txt", Marshal.dump(customer))
end

def seller
  Marshal.load(File.read("./db/seller.txt")) rescue nil
end

def customer
  Marshal.load(File.read("./db/customer.txt")) rescue nil
end
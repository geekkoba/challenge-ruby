require 'json'

def load_json(file)
  JSON.parse(File.read(file))
end

def process_data(users_file, companies_file, output_file)
  users = load_json(users_file)
  companies = load_json(companies_file)

  File.open(output_file, 'w') do |file|
    companies.sort_by { |company| company["id"] }.each do |company|
      
      company_users = users.select { |user| user['company_id'] == company['id'] && user['active_status'] }

      company_users.sort_by! { |user| user['last_name'] }

      emailed_users = []
      not_emailed_users = []

      company_users.each do |user|
        new_token_balance = user['tokens'] + company['top_up']

        if company['email_status'] && user['email_status']
          emailed_users << user.merge('new_token_balance' => new_token_balance)
        else
          not_emailed_users << user.merge('new_token_balance' => new_token_balance)
        end
      end

      
      next if emailed_users.empty? && not_emailed_users.empty?

      file.puts "Company Id: #{company['id']}"
      file.puts "Company Name: #{company['name']}"
      
      file.puts "Users Emailed:"
      if emailed_users.empty?
        file.puts "\tNone"
      else
        emailed_users.each do |user|
          file.puts "\t#{user['last_name']}, #{user['first_name']}, #{user['email']}"
          file.puts "\t  Previous Token Balance: #{user['tokens']}"
          file.puts "\t  New Token Balance: #{user['new_token_balance']}"
        end
      end

      file.puts "Users Not Emailed:"
      if not_emailed_users.empty?
        file.puts "\tNone"
      else
        not_emailed_users.each do |user|
          file.puts "\t#{user['last_name']}, #{user['first_name']}, #{user['email']}"
          file.puts "\t  Previous Token Balance: #{user['tokens']}"
          file.puts "\t  New Token Balance: #{user['new_token_balance']}"
        end
      end

      total_top_up = (emailed_users + not_emailed_users).sum { |user| company['top_up'] }
      file.puts "Total amount of top-ups for #{company['name']}: #{total_top_up}\n\n"
    end
  end
end

users_file = 'users.json'
companies_file = 'companies.json'
output_file = 'output.txt'

process_data(users_file, companies_file, output_file)
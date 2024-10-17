require 'json'

#--- function to load json from file ---#
def load_json(file)
  begin
    JSON.parse(File.read(file))
  rescue Errno::ENOENT
    puts "Error: File '#{file}' not found."
    exit(1)
  rescue JSON::ParserError
    puts "Error: File '#{file}' contains invalid JSON."
    exit(1)
  end
end

#--- main function ---#
def process_data(users_file, companies_file, output_file)
  users = load_json(users_file)
  companies = load_json(companies_file)

  begin
    File.open(output_file, 'w') do |file|
      companies.sort_by { |company| company["id"] }.each do |company|
        
        #--- filter users belongs to company ---#
        company_users = users.select { |user| user['company_id'] == company['id'] && user['active_status'] }
        #--- sort users by last name ---#
        company_users.sort_by! { |user| user['last_name'] }

        emailed_users = []
        not_emailed_users = []

        company_users.each do |user|
          begin
            #--- Ensure required fields are present ---#
            raise "Missing 'tokens' field for user #{user['id']}" unless user.key?('tokens')
            raise "Missing 'email_status' field for user #{user['id']}" unless user.key?('email_status')
            raise "Missing 'top_up' field for company #{company['name']}" unless company.key?('top_up')

            new_token_balance = user['tokens'] + company['top_up']
            
            if company['email_status'] && user['email_status']
              emailed_users << user.merge('new_token_balance' => new_token_balance)
            else
              not_emailed_users << user.merge('new_token_balance' => new_token_balance)
            end
          rescue => e
            puts "Error processing user #{user['id']} for company #{company['id']}: #{e.message}"
            next
          end
        end
        
        #--- skip if the company has no users --#
        next if emailed_users.empty? && not_emailed_users.empty?

        #--- puts company info --#
        file.puts "Company Id: #{company['id']}"
        file.puts "Company Name: #{company['name']}"
        
        #--- puts users emailed --#
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
        
        #--- puts users not emailed --#
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
        
        #--- puts total top up for company ---#
        total_top_up = (emailed_users + not_emailed_users).sum { |user| company['top_up'] }
        file.puts "Total amount of top-ups for #{company['name']}: #{total_top_up}\n\n"
      end
    end
    puts "Results have been written to #{output_file}"
  rescue Errno::EACCES
    puts "Error: Cannot write to the file '#{output_file}'. Check file permissions."
    exit(1)
  rescue => e
    puts "An unexpected error occurred: #{e.message}"
    exit(1)
  end
end

users_file = 'users.json'
companies_file = 'companies.json'
output_file = 'output.txt'

process_data(users_file, companies_file, output_file)
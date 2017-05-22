# Create the apache site
web_app "1-kwhs-wharton-upenn.edu" do
  template "apache-ssl-only-boilerplate.erb"
  server_name "kwhs.wharton.upenn.edu"
  server_aliases []
  document_root "/data/web/kwhs/current"
  cert_file site_cert_file
  cert_key site_key_file
  ca_chain site_ca_chain 
end

# Grab the settings from the "applications::kwhs" data bag
kwhs_settings = data_bag_item('applications','kwhs')
# Adjust for Chef Solo
settings_env = Chef::Config[:solo] ? "development" : node.chef_environment
db_settings = kwhs_settings[settings_env]["database"]
wp_settings = kwhs_settings[settings_env]["wp_params"]

# Deploy Using the PHP Application Cookbook
application "kwhs" do
  action :deploy
  path "/data/web/kwhs"
  owner node[:apache][:user]
  group node[:apache][:user]
  repository "git@HOST:USER/REPO.git"
  enable_submodules true
  deploy_key "-----BEGIN RSA PRIVATE KEY-----[KEY IN HERE]-----END RSA PRIVATE KEY-----"
  revision settings_env
  symlinks(
    "uploads" => "content/uploads",
    "wp-config.php" => "wp-config.php"
  )

  wordpress do
    local_settings_file   "wp-config.php"
    database do
      db_name       db_settings["db_name"]
      db_user       db_settings["db_user"]
      db_password   db_settings["db_password"]
      db_host       db_settings["db_host"]
      db_charset    db_settings["db_charset"]
      db_collate    db_settings["db_collate"]
      table_prefix  db_settings["table_prefix"]
    end
    wp_params do
      auth_key          wp_settings["auth_key"]
      secure_auth_key   wp_settings["secure_auth_key"] 
      logged_in_key     wp_settings["logged_in_key"] 
      nonce_key         wp_settings["nonce_key"]
      auth_salt         wp_settings["auth_salt"]
      secure_auth_salt  wp_settings["secure_auth_salt"]
      logged_in_salt    wp_settings["logged_in_salt"] 
      nonce_salt        wp_settings["nonce_salt"]
      wp_lang           wp_settings["wp_lang"]   
      display_errors    wp_settings["display_errors"] 
      wp_debug_display  wp_settings["wp_debug_display"] 
      wp_content_dir    '/data/web/kwhs/current/content'
      wp_content_url    'https://kwhs.wharton.upenn.edu/content'
    end
  end
  
end

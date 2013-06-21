# coding: utf-8
class User
  module OmniauthCallbacks
    ["github","google","twitter","douban"].each do |provider|
      define_method "find_or_create_for_#{provider}" do |response|
        uid = response["uid"]
        data = response["info"]

        if user = User.where("authorizations.provider" => provider , "authorizations.uid" => uid).first
          user
        else
          user = User.new_from_provider_data(provider, uid, data)

          if user.save(:validate => false)
            user.authorizations << Authorization.new(:provider => provider, :uid => uid )
            return user
          else
            Rails.logger.warn("User.create_from_hash 失败，#{user.errors.inspect}")
            return nil
          end
        end
      end
    end

    def new_from_provider_data(provider, uid, data)
      User.new do |user|
        if data["email"].present? && !User.where(:email => data["email"]).exists?
          user.email = data["email"]
        else
          user.email = "#{provider}+#{uid}@example.com"
        end
        user.name = data['name']

        user.nickname = data["nickname"]
        user.nickname = data["name"] if provider == "google"
        user.nickname.gsub!(/[^\w]/, "_")

        user.github = data['nickname'] if provider == "github"

        if User.where(:nickname => user.nickname).exists? || user.nickname.blank?
          user.nickname = "u#{Time.now.to_i}" # TODO: possibly duplicated user nickname here. What should we do?
        end

        user.password = Devise.friendly_token[0, 20]
        user.location = data["location"]
        user.tagline = data["description"]
      end
    end
  end
end

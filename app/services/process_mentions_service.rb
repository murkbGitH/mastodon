class ProcessMentionsService < BaseService
  # Scan status for mentions and fetch remote mentioned users, create
  # local mention pointers, send Salmon notifications to mentioned
  # remote users
  # @param [Status] status
  def call(status)
    status.text.scan(Account::MENTION_RE).each do |match|
      username, domain = match.first.split('@')
      local_account = Account.find_by(username: username, domain: domain)

      if local_account.nil?
        local_account = follow_remote_account_service.("acct:#{match.first}")
      end

      local_account.mentions.first_or_create(status: status)
    end

    status.mentions.each do |mentioned_account|
      next if mentioned_account.local?
      send_interaction_service.(status.stream_entry, mentioned_account)
    end
  end

  private

  def follow_remote_account_service
    @follow_remote_account_service ||= FollowRemoteAccountService.new
  end

  def send_interaction_service
    @send_interaction_service ||= SendInteractionService.new
  end
end

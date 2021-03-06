class YandexDirect::Add
  SERVICE = 'ads'
  attr_accessor :ad_group_id, :campaign_id, :id, :status, :state, :type, :status_clarification, :text, :title, :href, 
                :display_url_path, :ad_image_hash, :extension_ids, :mobile, :v_card_id, :sitelink_set_id

  def initialize(client)
    @client = client
  end

  def list(params)
    selection_criteria = {"Types":  ["TEXT_AD"]}
    selection_criteria["CampaignIds"] = params[:campaign_ids] if params[:campaign_ids].present?
    selection_criteria["AdGroupIds"] = params[:ad_group_ids] if params[:ad_group_ids].present?
    selection_criteria["Ids"] = params[:ids] if params[:ids].present?
    @client.request(SERVICE, 'get', { 
      "SelectionCriteria": selection_criteria,
      "FieldNames": ['AdGroupId', 'CampaignId', 'State', 'Status', 'StatusClarification', 'Type', 'Id'],
      "TextAdFieldNames": ['SitelinkSetId', 'Text', 'Title', 'Href']
    })["Ads"].to_a
  end

  def add(params)
    if params.kind_of?(Array)
      batch_add(params)
    else
      @client.request(SERVICE, 'add', {"Ads": [params]})["AddResults"].first
    end
  end

  def update(params)
    if params.kind_of?(Array)
      batch_update(params)
    else
      params['type'] ||= 'TextAd'
      params.id = @client.request(SERVICE, 'update', {"Ads": [params]})["UpdateResults"].first["Id"]
      params
    end
  end

  def unarchive(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('unarchive', ids)
  end

  def archive(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('archive', ids)
  end

  def stop(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('suspend', ids)
  end

  def resume(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('resume', ids)
  end

  def moderate(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('moderate', ids)
  end

  def delete(ids)
    ids = [ids] unless ids.kind_of?(Array)
    action('delete', ids)
  end

  def update_parameters(add_type)
    hash = {"Id": @id}
    hash[add_type.first] = add_type.last
    hash
  end

  def new_text_add_parameters
    hash = {"Text": @text, 
            "Title": @title,
            "Href": @href,
            "Mobile": @mobile || "NO",
            "AdExtensionIds": @extension_ids || []
           }
    hash["DisplayUrlPath"] = @display_url_path if @display_url_path.present?
    hash["VCardId"] = @v_card_id if @v_card_id.present?
    hash["AdImageHash"] = @ad_image_hash if @ad_image_hash.present?
    hash["SitelinkSetId"] = @sitelink_set_id if @sitelink_set_id.present?
    ["TextAd", hash]
  end

  def text_add_parameters
    hash = {"Text": @text, 
            "Title": @title,
            "Href": @href,
           }
    hash["DisplayUrlPath"] = @display_url_path if @display_url_path.present?
    hash["AdImageHash"] = @ad_image_hash if @ad_image_hash.present?
    hash["CalloutSetting"]["AdExtensions"] = @extension_ids.map{|e| {"AdExtensionId": e, "Operation": "SET"}} if @extension_ids.present?
    hash["VCardId"] = @v_card_id if @v_card_id.present?
    hash["SitelinkSetId"] = @sitelink_set_id if @sitelink_set_id.present?
    ["TextAd", hash]
  end

  private

  def batch_update(adds)
    params = adds.map do |params|
      params['type'] ||= 'TextAd'
      add_parameters(params)
    end
    params.each_slice(100) do |ads_parameters|
      @client.request(SERVICE, 'update', {"Ads": ads_parameters.compact})["UpdateResults"]
    end
  end

  def batch_add(adds)
    params = adds.map do |add|
      params['type'] ||= 'TextAd'
      add_parameters(params)
    end
    params.each_slice(100) do |ads_parameters|
      @client.request(SERVICE, 'add', {"Ads": ads_parameters.compact})["AddResults"]
    end
  end

  def action(action_name, ids)
    ids = ids.compact.reject{|id| id == 0}
    @client.request(SERVICE, action_name, {"SelectionCriteria": {"Ids": ids}}) if ids.any?
  end
end

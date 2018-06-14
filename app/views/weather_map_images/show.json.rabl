object @heatmap

attributes :id,
           :organization_token,
           :created_at,
           :updated_at

if @heatmap || (root_object && root_object != :heatmaps)
  file_to_use = @heatmap
  if root_object
    file_to_use = root_object
  end

end

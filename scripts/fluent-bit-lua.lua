function get_pod_ip(tag, timestamp, record)
  record.timestamp_iso = os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)
  if not string.find(tag, "ipamd.log") then
    return 1, timestamp, record -- Возвращаем 1, так как запись изменена
  end
  local pod_name, pod_ip = string.match(record.log, "Annotates pod (%S+) with vpc.amazonaws.com/pod%-ips: (.-)\"")
  if pod_name and pod_ip ~= nil then
    record.event_type = "ip_assignment"
    record.pod_name = pod_name
    if pod_ip == "" then
      record.assigned_ip = "IpDel"
    else
      record.assigned_ip = pod_ip
    end
    record.log = nil
  end
  return 1, timestamp, record
end

function create_field(tag, timestamp, record)
local event_type = "unknown"
if record["type"] and (record["type"] == "Normal" or record["type"] == "Warning" or record["type"] == "Error") then
  event_type = string.lower(record["type"])
end
local ns = "unclassified"
local name = "unclassified"
if type(record["involvedObject"]) == "table" then
  ns = record["involvedObject"]["namespace"] or ns
  name = record["involvedObject"]["name"] or name
end
record["new_built_tag"] = "application.event." .. event_type .. "." .. name .. "_" .. ns
return 1, timestamp, record
end

function create_field_o(tag, timestamp, record)
  local new_tag_value
  if record["type"] and (record["type"] == "Warning" or record["type"] == "Error") then
    local event_type = string.lower(record["type"])
    local ns = (record["involvedObject"] and record["involvedObject"]["namespace"]) or "unclassified"
    local name = (record["involvedObject"] and record["involvedObject"]["name"]) or "unclassified"
    new_tag_value = "application.event." .. event_type .. "." .. name .. "_" .. ns
  else
    new_tag_value = "events-to-drop"
  end
  record["new_tag"] = new_tag_value
  return 1, timestamp, record
end

function filter_stdout1(tag, timestamp, record)
  if record["stream1"] and record["stream1"] == "stdout" then
    record["retag_to_drop"] = "true"
  end
  return 1, timestamp, record
end

-- ##########################################
local allowlist = {
  ["ingress-nginx"] = {
    ["controller"] = {
      "STATUS=5%d%d"
    }
  },
  ["internal-nginx"] = {
    ["controller"] = {
      "STATUS=5%d%d"
    }
  }
}
-- ====================================================================
--      Main Filter Function
-- ====================================================================
function filter_stdout(tag, timestamp, record)
  if not record["stream"] or record["stream"] ~= "stdout" then
    return 1, timestamp, record
  end

  local kube_meta = record.kubernetes
  if kube_meta and kube_meta.namespace_name and kube_meta.container_name then
    local namespace = kube_meta.namespace_name
    local container = kube_meta.container_name
    if allowlist[namespace] and allowlist[namespace][container] then
      local rule = allowlist[namespace][container]
      if type(rule) == "boolean" and rule == true then
        -- KEEP ALL
        return 1, timestamp, record
      elseif type(rule) == "table" then
        -- KEEP BY CONDITION (Patterns/Regex)
        if record["log"] and type(record["log"]) == "string" then
          for _, pattern_to_find in ipairs(rule) do
            if string.find(record["log"], pattern_to_find) then
              return 1, timestamp, record
            end
          end
        end
      end
    end
  end
  -- 4. FINAL DECISION: none of the keep rules were met.
  --    This is a "noisy" stdout log that needs to be dropped. Mark it.
  record["retag_to_drop"] = "true"
  return 1, timestamp, record
end
-- ##########################################

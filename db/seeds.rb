::Sunspot.session = ::Sunspot::Rails::StubSessionProxy.new(::Sunspot.session)

# Create two organizations
o = Organization.create({short_name:'US-CERT',long_name:'United States Computer Emergency Readiness Team'})
o2 = Organization.create({short_name:'CISCP',long_name:'CISCP'})

# First create permissions
yml = YAML.load_file('config/permissions.yml')
(yml[Rails.env]||[]).each do |name,attributes|
  unless Permission.find_by_name(name)
    p = Permission.new
    p.name = name
    p.display_name = attributes['display_name']
    p.description = attributes['description']
    p.created_at = Time.now
    p.updated_at = Time.now
    p.guid = SecureRandom.uuid
    p.save
    puts "Created permission "+p.name
  end
end
# Now create groups with the proper permissions
yml = YAML.load_file('config/groups.yml')
yml.each do |name,attributes|
  unless Group.find_by_name(attributes['name'])
    g = Group.new
    g.name = attributes['name']
    g.description = attributes['description']
    g.created_at = Time.now
    g.updated_at = Time.now
    g.guid = SecureRandom.uuid
    g.save
    puts "Created group "+g.name
  end
end
# Now add the proper permissions to each group
yml.each do |name,attributes|
  g = Group.find_by_name(attributes['name'])
  unless attributes['permissions'].nil?
    perms = []
    permissions = attributes['permissions'].strip.split /\s+/
    permissions.each do |permission|
      p = Permission.find_by_name(permission)
      if GroupPermission.where("group_id=? and permission_id=?",g.id,p.id).empty?
        gp = GroupPermission.new
        gp.group_id = g.id
        gp.permission_id = p.id
        gp.created_at = Time.now
        gp.guid = SecureRandom.uuid
        gp.save
        puts "Added "+p.name+" to "+g.name
      end
    end
  end
end

g_admin = Group.find_by_name('Admin')
g_trusted_user = Group.find_by_name('Trusted User')

# Create svcadmin user
u = User.create!(username: 'svcadmin',
                 email: 'svcadmin@indicators.app',
                 password: 'P@ssw0rd!',
                 password_confirmation: 'P@ssw0rd!',
                 first_name: 'Admin',
                 last_name: 'User',
                 organization_guid: o.guid,
                 terms_accepted_at: Time.now)

# Add Admin group to 'svcadmin'
u.groups << g_admin
u.save

# Create first trusted user
trusted1 = User.create!(username: 'trusted_user',
                        email: 'trusted_user@indicators.app',
                        password: 'P@ssw0rd!',
                        password_confirmation: 'P@ssw0rd!',
                        first_name: 'Trusted',
                        last_name: 'User',
                        organization_guid: o.guid)

# Add Trusted User group to 'trusted_user'
trusted1.groups << g_trusted_user
trusted1.save

# Create second trusted user
trusted2 = User.create!(username: 'trusted_user2',
                        email: 'trusted_user2@indicators.app',
                        password: 'P@ssw0rd!',
                        password_confirmation: 'P@ssw0rd!',
                        first_name: 'Trusted',
                        last_name: 'User',
                        organization_guid: o2.guid)

# Add Trusted User group to 'trusted_user2'
trusted2.groups << g_trusted_user
trusted2.save

# Create machine user
machine_user = User.create(username: 'machine_user',
                           email: 'machine_user@indicators.app',
                           password: 'P@ssw0rd!',
                           password_confirmation: 'P@ssw0rd!',
                           first_name: 'Machine',
                           last_name: 'User',
                           organization_guid: o.guid)

machine_user.groups << g_admin

# API_KEY: 7a3c834c1f07d46f2384b52df686fb24de499bff14c48112750b0d55c7b7e126
# API_KEY_HASH: f9e274e528d0733b4454a91bb8db2edc30b78fe356fe9f2f87f527aca06d57fb
machine_user.api_key = "7a3c834c1f07d46f2384b52df686fb24de499bff14c48112750b0d55c7b7e126"
machine_user.change_api_key_secret("P@ssw0rd!")
machine_user.machine = true
machine_user.save

# There are hooks in the models to set who created the indicators.  This is what they go from
User.current_user = User.first

s1 = Sighting.create!(description: "MIFR-1111", sighted_at: Time.now)
s2 = Sighting.create!(description: "DMAR-2222", sighted_at: Time.now.months_ago(1))
s3 = Sighting.create!(description: "PDMAR-3333", sighted_at: Time.now.months_ago(2))

mark_and_save = []

mark_and_save << Indicator.new(title: 'first',description: "This is the first indicator\r\nThis is a multiline description", indicator_type: "Exfiltration", downgrade_request_id: 'DHS:00c26859-dae1-4c89-b421-b715a48c584f', portion_marking: 'U')
mark_and_save << Indicator.new(title: 'second',description: "This is the second indicator", indicator_type: "Compromised PKI Certificate", portion_marking: 'U')
mark_and_save << Indicator.new(title: 'third',description: "This is the third indicator", indicator_type: "Domain Watchlist", portion_marking: 'U')

i4 = Indicator.new(title: 'Domain indicator',description: "This is a domain indicator", indicator_type: "C2", stix_id: "#{Setting.STIX_PREFIX}:Indicator-6bb61900-2258-11e4-8c21-0800200c9a66",downgrade_request_id: 'DHS:00c26859-dae1-4c89-b421-b715a48c584f', portion_marking: 'U')
mark_and_save << i4

d1 = Domain.new(name_raw: "www.google.com", name_condition: 'Equals', portion_marking: 'U')
mark_and_save << d1

mark_and_save << Observable.new(indicator: i4, object: d1)

i5 = Indicator.new(title: 'Example watchlist untrusted malware source',description: "This is an example indicator", indicator_type: "Exfiltration", stix_id: "#{Setting.STIX_PREFIX}:Indicator-6bb61900-2258-11e4-8c21-0800200caa66", portion_marking: 'U')
mark_and_save << i5

a1 = Address.new(address_value_raw: "147.27.180.39", portion_marking: 'U')
mark_and_save << a1

mark_and_save << Observable.new(indicator: i5, object: a1)

Rake::Task['weather:acs_set'].execute

#wmd1 = WeatherMapData.new(ip_address_raw: '147.27.180.39',iso_country_code:'USA',com_threat_score:'0.59',gov_threat_score:'0.23',combined_score:'6.55',agencies_sensors_seen_on:'CSOSA52M-DOLM-DOT7-FAA45',first_date_seen_raw:'2015-01-25 13:09:03 -0500"',last_date_seen_raw:'2015-02-25 14:09:03 -0500"',category_list:'Malware & Botnet: Malware Command and Control-Malware & Botnet: Host Behavior-Malware & Botnet: Backdoor Rat')
#wmd2 = WeatherMapData.new(ip_address_raw: '231.85.218.1',iso_country_code:'UK',com_threat_score:'0.18',gov_threat_score:'0.09',combined_score:'8.10',agencies_sensors_seen_on:'HHS20-HRSA22-IHS8',first_date_seen_raw:'2015-02-01 13:09:03 -0500"',last_date_seen_raw:'2015-02-04 13:09:03 -0500"',category_list:'Malware & Botnet: Malware C2-Malware & Botnet: Host Behavior-Malware & Botnet: Backdoor Rat')
#wmd3 = WeatherMapData.new(ip_address_raw: '207.227.14.196',iso_country_code:'BR',com_threat_score:'0.99',gov_threat_score:'0.99',combined_score:'9.22',agencies_sensors_seen_on:'IHS8-ITO9-NASA41-NIH16-NIST3G-OPM7-USDA4-USDA5-USPS2M',first_date_seen_raw:'2014-11-25 13:09:03 -0500"',last_date_seen_raw:'2015-02-25 13:09:03 -0500"',category_list:'Malware & Botnet: Malware Command and Control-Malware & Botnet: Host Behavior-Malware & Botnet: Backdoor Rat')

i5_2 = Indicator.new(title: 'IP Address range indicator',description: "IP Address with a range", indicator_type: "Benign", stix_id: "#{Setting.STIX_PREFIX}:Indicator-47b895c3-8d62-4f7b-a955-f0033d8de816", portion_marking: 'U')
mark_and_save << i5_2
a1_2 = Address.new(address_value_raw: "10.24.2.0/24", portion_marking: 'U')
mark_and_save << a1_2
mark_and_save << Observable.new(indicator: i5_2, object: a1_2)

i5_3 = Indicator.new(title: 'IP Address indicator with /32 prefix',description: "This is an ip address indicator", indicator_type: "Benign", stix_id: "#{Setting.STIX_PREFIX}:Indicator-753ade45-fafc-4626-9c5b-1caa651b2f11", portion_marking: 'U')
mark_and_save << i5_3
a1_3 = Address.new(address_value_raw: "5.6.7.8/32", portion_marking: 'U')
mark_and_save << a1_3
mark_and_save << Observable.new(indicator: i5_3, object: a1_3)

mark_and_save << Address.new(address_value_raw: "::1", portion_marking: 'U')
mark_and_save << Address.new(address_value_raw: "127.0.0.1", portion_marking: 'U')
mark_and_save << Address.new(address_value_raw: "192.168.0.1", portion_marking: 'U')
mark_and_save << Address.new(address_value_raw: "13.24.35.47", portion_marking: 'U')
mark_and_save << Address.new(address_value_raw: "4.7.2.8", portion_marking: 'U')

i6 = Indicator.new(title: 'URI indicator',description: "This is a uri indicator", indicator_type: "URL Watchlist", stix_id: "#{Setting.STIX_PREFIX}:Indicator-6bb61900-2258-11e4-8c21-0800200cba66", portion_marking: 'U')
mark_and_save << i6
u1 = Uri.new(uri_raw: "http://www.cnn.com", portion_marking: 'U')
mark_and_save << u1
mark_and_save << Observable.new(indicator: i6, object: u1)

i7 = Indicator.new(title: 'Email indicator',description: "This is an email indicator", indicator_type: "Malicious E-mail", portion_marking: 'U')
mark_and_save << i7
e1 = EmailMessage.new(from_raw: 'from@from.com',reply_to_raw: 'replyto@replyto.com',sender_raw: 'sender@sender.com',subject: 'Test subject', portion_marking: 'U')
mark_and_save << e1
mark_and_save << Observable.new(indicator: i7, object: e1)

i8 = Indicator.new(title: 'DNS record indicator',description: "This is a DNS record indicator", indicator_type: "C2", portion_marking: 'U')
mark_and_save << i8
d2 = DnsRecord.new(address_value_raw: '1.2.3.4',address_class: 'IN',domain_raw: 'www.blah.com',entry_type: 'MX', portion_marking: 'U')
mark_and_save << d2
mark_and_save << Observable.new(indicator: i8, object: d2)

i9 = Indicator.new(title: 'File indicator',description: "This is a file indicator", indicator_type: "File Hash Watchlist", portion_marking: 'U')
mark_and_save << i9

fh1 = FileHash.new(hash_type: 'MD5', simple_hash_value: '12345678901234567890123456789012')
mark_and_save << fh1
fh2 = FileHash.new(hash_type: 'SHA1', simple_hash_value: '1234567890123456789012345678901234567890')
mark_and_save << fh2
fh3 = FileHash.new(hash_type: 'SHA256', simple_hash_value: '1234567890123456789012345678901234567890123456789012345678901234')
mark_and_save << fh3
fh4 = FileHash.new(hash_type: 'SSDEEP', fuzzy_hash_value: 'ssdeepvalue')
mark_and_save << fh4
f1 = CyboxFile.new(file_name: 'bad_file.exe', file_name_condition: 'Equals', portion_marking: 'U')
f1.file_hashes << fh1
f1.file_hashes << fh2
f1.file_hashes << fh3
f1.file_hashes << fh4
mark_and_save << f1
mark_and_save << Observable.new(indicator: i9, object: f1)

i10 = Indicator.new(title: 'HTTP session indicator',description: "This is a HTTP session indicator", indicator_type: "Malware Artifacts", portion_marking: 'U')
mark_and_save << i10
h1 = HttpSession.new(user_agent: 'Mozilla', domain_name: 'en.wikipedia.org', port: '8080', referer: 'google.com', pragma: 'no-cache', portion_marking: 'U')
mark_and_save << h1
mark_and_save << Observable.new(indicator: i10, object: h1)

i11 = Indicator.new(title: 'Mutex indicator',description: "This is a mutex indicator", indicator_type: "Malware Artifacts", portion_marking: 'U')
mark_and_save << i11
m1 = CyboxMutex.new(name: 'Mutex', portion_marking: 'U')
mark_and_save << m1
mark_and_save << Observable.new(indicator: i11, object: m1)

i12 = Indicator.new(title: 'Registry indicator',description: "This is a registry indicator", indicator_type: "Malware Artifacts", portion_marking: 'U')
mark_and_save << i12

rv1 = RegistryValue.new(reg_name: 'name', reg_value: 'value')
mark_and_save << rv1
r1 = Registry.new(hive: 'HKEY_LOCAL_MACHINE', key: 'key', portion_marking: 'U')
r1.registry_values << rv1
mark_and_save << r1
mark_and_save << Observable.new(indicator: i12, object: r1)

i13 = Indicator.new(title: 'Network connection indicator',description: "This is a network connection indicator", indicator_type: "Malware Artifacts", portion_marking: 'U')
mark_and_save << i13
n1 = NetworkConnection.new(dest_socket_address: '1.2.3.4', dest_socket_is_spoofed: true, dest_socket_port: '80',
                               source_socket_address: '4.3.2.1', source_socket_port: '80', layer4_protocol: 'TCP', portion_marking: 'U')
mark_and_save << n1
mark_and_save << Observable.new(indicator: i13, object: n1)

i14 = Indicator.new(title: 'Link indicator',description: "This is a Link indicator", indicator_type: "Malware Artifacts", stix_id: "#{Setting.STIX_PREFIX}:Indicator-6bb61900-2258-11e4-8c21-0140200cba14", portion_marking: 'U')
mark_and_save << i14
link1 = Link.new(label: "cnn.com", portion_marking: 'U')
link1.uri = u1
mark_and_save << link1
mark_and_save << Observable.new(indicator: i14, object: link1)

p1 = StixPackage.new(title: 'New Package',description: "This is a package with an indicator",short_description: "indicator package",username: "user", portion_marking: 'U')
mark_and_save << p1

mark_and_save << Indicator.new(title: 'Packaged Indicator',description: "This is a packaged indicator",indicator_type: "Benign", portion_marking: 'U')

(1..100).each do |x|
  i = Indicator.new(title: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", description: "description", indicator_type: "Benign", portion_marking: 'U')

  r = rand(17)
  if r == 0
    o = Address.new(address_value_raw: IPAddr.new(rand(2**32),Socket::AF_INET).to_s, portion_marking: 'U')
  elsif r == 1
    o = DnsRecord.new(address_value_raw: IPAddr.new(rand(2**32),Socket::AF_INET).to_s, address_class: 'IN', domain_raw: "www.#{(0...8).map { (65 + rand(26)).chr }.join}.com", entry_type: 'MX', portion_marking: 'U')
  elsif r == 2
    o = Domain.new(name_raw: "www.#{(0...8).map { (65 + rand(26)).chr }.join}.com", name_condition: 'Equals', portion_marking: 'U')
  elsif r == 3
    o = EmailMessage.new(sender_raw: "#{(0...8).map { (65 + rand(26)).chr }.join}@#{(0...8).map { (65 + rand(26)).chr }.join}.com", reply_to_raw: "#{(0...8).map { (65 + rand(26)).chr }.join}@#{(0...8).map { (65 + rand(26)).chr }.join}.com", from_raw: "#{(0...8).map { (65 + rand(26)).chr }.join}@#{(0...8).map { (65 + rand(26)).chr }.join}.com", subject: "#{(0...8).map { (65 + rand(26)).chr }.join}@#{(0...8).map { (65 + rand(26)).chr }.join}.com", portion_marking: 'U')
  elsif r == 4
    fh1 = FileHash.new(hash_type: 'MD5', simple_hash_value: "#{(0...32).map { [(48 + rand(10)).chr, (97 + rand(6)).chr].sample }.join}")
    mark_and_save << fh1
    fh2 = FileHash.new(hash_type: 'SHA1', simple_hash_value: "#{(0...40).map { [(48 + rand(10)).chr, (97 + rand(6)).chr].sample }.join}")
    mark_and_save << fh2
    fh3 = FileHash.new(hash_type: 'SHA256', simple_hash_value: "#{(0...64).map { [(48 + rand(10)).chr, (97 + rand(6)).chr].sample }.join}")
    mark_and_save << fh3
    fh4 = FileHash.new(hash_type: 'SSDEEP', fuzzy_hash_value: "SSDEEP_#{RandomWord.adjs.next}_#{RandomWord.nouns.next}")
    mark_and_save << fh4
    o = CyboxFile.new(file_name: "#{RandomWord.adjs.next}_#{RandomWord.nouns.next}.exe", file_name_condition: 'Equals', portion_marking: 'U')
    o.file_hashes << fh1
    o.file_hashes << fh2
    o.file_hashes << fh3
    o.file_hashes << fh4
  elsif r == 5
    o = HttpSession.new(user_agent: 'Mozilla', domain_name: "#{RandomWord.adjs.next}.wikipedia.org", port: '8080', referer: "#{RandomWord.adjs.next}.#{RandomWord.nouns.next}.com", pragma: 'no-cache', portion_marking: 'U')
  elsif r == 6
    u1 = Uri.new(uri_raw: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
    mark_and_save << u1
    o = Link.new(label: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
    o.uri = u1
  elsif r == 7
    o = CyboxMutex.new(name: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
  elsif r == 8
    o = NetworkConnection.new(dest_socket_address: IPAddr.new(rand(2**32),Socket::AF_INET).to_s, dest_socket_is_spoofed: true, dest_socket_port: "#{(0...4).map { (48 + rand(10)).chr }.join}", source_socket_address: IPAddr.new(rand(2**32),Socket::AF_INET).to_s, source_socket_port: "#{(0...4).map { (48 + rand(10)).chr }.join}", layer4_protocol: 'TCP', portion_marking: 'U')
  elsif r == 9
    rv1 = RegistryValue.new(reg_name: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", reg_value: "#{(0...4).map { (48 + rand(10)).chr }.join}")
    mark_and_save << rv1
    o = Registry.new(hive: 'HKEY_LOCAL_MACHINE', key: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
    o.registry_values << rv1
  elsif r == 10
    o = Uri.new(uri_raw: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
  elsif r == 11
    o = Port.new(port: "#{(0...4).map { (48 + rand(10)).chr }.join}", layer4_protocol: 'TCP', portion_marking: 'U')
  elsif r == 12
    o = Hostname.new(hostname: "#{RandomWord.adjs.next}.wikipedia.org",hostname_condition: 'Equals', naming_system: 'DNS', portion_marking: 'U')
  elsif r == 13
    o = SocketAddress.new(portion_marking: 'U')
    rr = rand(5)
    if rr == 0
      sample = mark_and_save.find_all {|x| x.class == Address}.sample
      o.addresses << sample if sample.present?
    elsif rr == 1
      sample = mark_and_save.find_all {|x| x.class == Hostname}.sample
      o.hostnames << sample if sample.present?
    elsif rr == 2
      sample = mark_and_save.find_all {|x| x.class == Port}.sample
      o.ports << sample if sample.present?
    elsif rr == 3
      sample = mark_and_save.find_all {|x| x.class == Address}.sample
      o.addresses << sample if sample.present?
      sample = mark_and_save.find_all {|x| x.class == Port}.sample
      o.ports << sample if sample.present?
    elsif rr == 4
      sample = mark_and_save.find_all {|x| x.class == Hostname}.sample
      o.hostnames << sample if sample.present?
      sample = mark_and_save.find_all {|x| x.class == Port}.sample
      o.ports << sample if sample.present?
    end
  ## Lets add some threat actors and COAs
  elsif r == 14
    o = ThreatActor.new(title: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
  elsif r == 15
    o = CourseOfAction.new(title: "#{RandomWord.adjs.next} #{RandomWord.nouns.next} #{x}", portion_marking: 'U')
  elsif r == 16
    o = DnsQuery.new(portion_marking: 'U')
  end

  i.title = i.title + "- " + o.class.to_s if Observable::CYBOX_OBJECTS.include?(o.class.to_s.underscore.pluralize.to_sym)
  mark_and_save << i
  mark_and_save << o
  mark_and_save << Observable.new(indicator: i, object: o) if Observable::CYBOX_OBJECTS.include?(o.class.to_s.underscore.pluralize.to_sym)
end

# Create default markings for valid classes and use is_upload to spoof till later
mark_and_save.each do |e|
  e.is_upload = true
  e.save!

  if StixMarking::VALID_CLASSES.include?(e.class.to_s) && e.class.respond_to?(:create_default_policy)
    e.class.create_default_policy(e)
  end
  e.reload
end

# Add the indicators to the default package and set is_upload to false
mark_and_save.each do |e|
  if e.class.to_s == "Indicator"
    p1.indicators << e
  end
  e.is_upload = false
end

SystemTag.reset_column_information

%w{
  red
  blue
  green
  black
  grey
  orange
  yellow
  purple
  FO01
  FO02
  bad
  good
  terrible
  aardvark
  abraham
  bellman
  brock
  change
  collected
  delta
  dingo
  ephemeral
  eager
  final
  fink
  great
  gortex
  helium
  helmut
  hostile
  indigo
  interesting
  jinkies
  jello
  klingon
  kite
  lima
  lemur
  magnet
  mongo
  new
  nearest
  opal
  opossum
  pelican
  pendulum
  quixotic
  quincy
  region
  real
  super
  sunken
  tender
  transfer
  union
  unified
  vetted
  viscious
  watchlist
  weary
  xtinct
  yell
  zyzzyva
}.map do |tag_name|
  SystemTag.create!(name: tag_name)
end

fo01 = SystemTag.find_by_name("FO01")
i5.system_tags << fo01
i5_2.system_tags << fo01
i4.system_tags << fo01
fo02 = SystemTag.find_by_name("FO02")
i5.system_tags << fo02

Indicator.all.each do |indicator|
  (1..rand(6)).each do
    user = User.all.sample
    Confidence.create(value: Confidence::VALID_CONFIDENCES[rand(2)+1],
                      description: "Ingested Confidence",
                      is_official: [true,false].sample,
                      user: User.all.sample,
                      remote_object_id: indicator.guid,
                      remote_object_type: indicator.class.to_s
    )
  end
  (0..rand(3)).each do
    tag = SystemTag.all.sample
    indicator.system_tags << tag
  end
end

# Lets create some default acs sets if were in the classified env
if Setting.CLASSIFICATION == true
  Classification::CLASSIFICATIONS.each do |c|
    isa_assertion = IsaAssertionStructure.new(AcsDefault::ASSERTION_DEFAULTS)

    isa_assertion.cs_classification = c.to_s

    if Classification::CLASSIFICATIONS.index(c.to_s) > 0
      isa_assertion.classified_on = Time.now
      isa_assertion.classified_by = "#{RandomWord.adjs.next} #{RandomWord.nouns.next}"
      isa_assertion.classification_reason = "#{RandomWord.adjs.next} #{RandomWord.nouns.next}"
    end

    isa_privs = AcsDefault::PRIVS_DEFAULTS.collect do |priv|
      IsaPriv.new(priv)
    end
    stix_marking = StixMarking.new(
        is_reference: false
    )

    stix_marking.isa_assertion_structure = isa_assertion
    stix_marking.isa_assertion_structure.isa_privs = isa_privs

    acs_set = AcsSet.new(name: "Default Markings for Classification: #{c.to_s}", locked: true)
    acs_set.stix_markings << stix_marking
    acs_set.save
  end
end

Password.all.each {|p| p.requires_change = false;p.save}
::Sunspot.session = ::Sunspot.session.original_session
Rake::Task["sunspot:solr:reindex"].invoke

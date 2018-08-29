Stix JSON Example files here:

https://oasis-open.github.io/cti-documentation/stix/examples.html

Stix XML sample files in this folder and here:

http://stixproject.github.io/documentation/idioms/

# XML VS JSON

## Threat Actor Leveraging Attack Patterns and Malware [(XML):](http://stixproject.github.io/documentation/idioms/leveraged-ttp/)
```xml
<stix:TTPs>
        <stix:TTP id="example:ttp-8ac90ff3-ecf8-4835-95b8-6aea6a623df5" xsi:type='ttp:TTPType' version="1.1">
            <ttp:Title>Phishing</ttp:Title>
            <ttp:Behavior>
                <ttp:Attack_Patterns>
                    <ttp:Attack_Pattern capec_id="CAPEC-98">
                        <ttp:Description>Phishing</ttp:Description>
                    </ttp:Attack_Pattern>
                </ttp:Attack_Patterns>
            </ttp:Behavior>
        </stix:TTP>
        <stix:TTP id="example:ttp-d1c612bc-146f-4b65-b7b0-9a54a14150a4" xsi:type='ttp:TTPType' version="1.1">
            <ttp:Title>Poison Ivy Variant d1c6</ttp:Title>
            <ttp:Behavior>
                <ttp:Malware>
                    <ttp:Malware_Instance id="example:malware-1621d4d2-b67d-11e3-ba9e-f01faf20d111">
                        <ttp:Type xsi:type="stixVocabs:MalwareTypeVocab-1.0">Remote Access Trojan</ttp:Type>
                        <ttp:Name>Poison Ivy Variant d1c6</ttp:Name>
                    </ttp:Malware_Instance>
                </ttp:Malware>
            </ttp:Behavior>
        </stix:TTP>
    </stix:TTPs>
    <stix:Threat_Actors>
        <stix:Threat_Actor id="example:threatactor-9a8a0d25-7636-429b-a99e-b2a73cd0f11f" xsi:type='ta:ThreatActorType' version="1.1">
            <ta:Title>Adversary Bravo</ta:Title>
            <ta:Identity id="example:Identity-1621d4d4-b67d-11e3-9670-f01faf20d111">
                <stixCommon:Name>Adversary Bravo</stixCommon:Name>
            </ta:Identity>
            <ta:Observed_TTPs>
                <ta:Observed_TTP>
                    <stixCommon:Relationship>Leverages Attack Pattern</stixCommon:Relationship>
                    <stixCommon:TTP idref="example:ttp-8ac90ff3-ecf8-4835-95b8-6aea6a623df5"/>
                </ta:Observed_TTP>
                <ta:Observed_TTP>
                    <stixCommon:Relationship>Leverages Malware</stixCommon:Relationship>
                    <stixCommon:TTP idref="example:ttp-d1c612bc-146f-4b65-b7b0-9a54a14150a4"/>
                </ta:Observed_TTP>
            </ta:Observed_TTPs>
        </stix:Threat_Actor>
    </stix:Threat_Actors>
```

## Threat Actor Leveraging Attack Patterns and Malware [(JSON):](https://oasis-open.github.io/cti-documentation/examples/threat-actor-leveraging-attack-patterns-and-malware)

```json
{
  "type": "bundle",
  "id": "bundle--44af6c39-c09b-49c5-9de2-394224b04982",
  "spec_version": "2.0",
  "objects": [
    {
      "type": "attack-pattern",
      "id": "attack-pattern--8ac90ff3-ecf8-4835-95b8-6aea6a623df5",
      "created": "2015-05-07T14:22:14.760Z",
      "modified": "2015-05-07T14:22:14.760Z",
      "name": "Phishing",
      "description": "Spear phishing used as a delivery mechanism for malware.",
      "external_references": [
        {
          "source_name": "capec",
          "description": "phishing",
          "url": "https://capec.mitre.org/data/definitions/98.html",
          "external_id": "CAPEC-98"
        }
      ],
      "kill_chain_phases": [
        {
          "kill_chain_name": "mandiant-attack-lifecycle-model",
          "phase_name": "initial-compromise"
        }
      ]
    },
    {
      "type": "identity",
      "id": "identity--1621d4d4-b67d-11e3-9670-f01faf20d111",
      "created": "2015-05-10T16:27:17.760Z",
      "modified": "2015-05-10T16:27:17.760Z",
      "name": "Adversary Bravo",
      "description": "Adversary Bravo is a threat actor that utilizes phishing attacks",
      "identity_class": "unknown"
    },
    {
      "type": "threat-actor",
      "id": "threat-actor--9a8a0d25-7636-429b-a99e-b2a73cd0f11f",
      "created": "2015-05-07T14:22:14.760Z",
      "modified": "2015-05-07T14:22:14.760Z",
      "name": "Adversary Bravo",
      "description": "Adversary Bravo is known to use phishing attacks to deliver remote access malware to the targets.",
      "labels": [
        "spy",
        "criminal"
      ]
    },
    {
      "type": "malware",
      "id": "malware--d1c612bc-146f-4b65-b7b0-9a54a14150a4",
      "created": "2015-04-23T11:12:34.760Z",
      "modified": "2015-04-23T11:12:34.760Z",
      "name": "Poison Ivy Variant d1c6",
      "labels": [
        "remote-access-trojan"
      ],
      "kill_chain_phases": [
        {
          "kill_chain_name": "mandiant-attack-lifecycle-model",
          "phase_name": "initial-compromise"
        }
      ]
    },
    {
      "type": "relationship",
      "id": "relationship--ad4bccee-1ed3-44f5-9a56-8085584d3360",
      "created": "2015-05-07T14:22:14.760Z",
      "modified": "2015-05-07T14:22:14.760Z",
      "relationship_type": "uses",
      "source_ref": "threat-actor--9a8a0d25-7636-429b-a99e-b2a73cd0f11f",
      "target_ref": "malware--d1c612bc-146f-4b65-b7b0-9a54a14150a4"
    },
    {
      "type": "relationship",
      "id": "relationship--e05a50c3-a557-4d5f-ac19-e3f0859171cc",
      "created": "2015-05-07T14:22:14.760Z",
      "modified": "2015-05-07T14:22:14.760Z",
      "relationship_type": "uses",
      "source_ref": "threat-actor--9a8a0d25-7636-429b-a99e-b2a73cd0f11f",
      "target_ref": "attack-pattern--8ac90ff3-ecf8-4835-95b8-6aea6a623df5"
    },
    {
      "type": "relationship",
      "id": "relationship--bdcef81d-9dfa-4f5d-a7e5-7ab13b695495",
      "created": "2015-05-07T14:22:14.760Z",
      "modified": "2015-05-07T14:22:14.760Z",
      "relationship_type": "attributed-to",
      "source_ref": "threat-actor--9a8a0d25-7636-429b-a99e-b2a73cd0f11f",
      "target_ref": "identity--1621d4d4-b67d-11e3-9670-f01faf20d111"
    }
  ]
}
```

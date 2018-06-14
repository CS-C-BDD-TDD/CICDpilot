collection @groups

#extends "groups/show", locals: {associations: locals[:associations].merge(audits: 'none')}
# Commented out above and added below to allow testing of audits
extends "groups/show", locals: {associations: locals[:associations]}

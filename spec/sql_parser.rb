

r = Regexp.new('^create')

r.match('create') or raise 'create'

identa = Array.new
identa.push '(?:[_[:alpha]][_$[:alnum:]]*)'
identa.push '(?:"(?:[^"]|"")*")'
ident = identa.join('|')

r = Regexp.new('^create\s+(?:(?:temporary|temp)\s+)*table\s+')
reg = 
'^create\s+(?:(?:temporary|temp)\s+)?table\s' +
'(?:if not exists\s+)?' +
'(?:'+ ident + '\.)?' + ident
r = Regexp.new(reg)

r.match('create table bob') or raise 'create table bob'
r.match('create temporary table bob') or raise 'create temporary table bob'
r.match('create temp table bob') or raise 'create temp table bob'
r.match('create table if not exists bob') or raise 'create table bob'


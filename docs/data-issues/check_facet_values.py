#!/usr/bin/env python3
"""List glitches in the values of the facet fields (the ones the browse cards and home page facets use).

    python3 docs/data-issues/check_facet_values.py [_data/metadata-full.csv] [docs/data-issues/facet-value-issues.csv]

Each row of the output names one problem: the field, the kind of problem, the value, how many objects
have it, a related value where there is one, example object ids, and a suggestion. The glitches are in
the data that comes from Airtable, so they need fixing there; this script only finds them.
Terms in a field are separated by semicolons, as on the site.
"""
import csv
import difflib
import re
import sys
from collections import Counter, defaultdict

SRC = sys.argv[1] if len(sys.argv) > 1 else '_data/metadata-full.csv'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'docs/data-issues/facet-value-issues.csv'

# the facet fields: short controlled terms. (findspot and the description fields are free text with
# markup that the site handles, so they are not checked.)
FIELDS = ('building_type ceramic_phase material object_function painter period periods sculptor shape '
          'sculpture_type site_type style technique ware context region collection').split()


def norm(term):
    """The term without case, punctuation, uncertainty marks, hyphens and spacing."""
    t = re.sub(r'\(\?\)|\?', '', term.lower())
    t = re.sub(r'[^\w\s/]', ' ', t)
    return re.sub(r'\s+', ' ', t).strip()


def uncertain(term):
    return '?' in term


def base(term):
    """The term with its uncertainty marks removed."""
    return re.sub(r'\s+', ' ', re.sub(r'\s*\(\?\)|\?', '', term)).strip()


objects = [r for r in csv.DictReader(open(SRC, encoding='utf-8')) if r['objtype']]
rows = []


def add(issue, field, value, count, other='', other_count='', ids=(), suggestion=''):
    rows.append({'issue': issue, 'field': field, 'value': value, 'objects': count, 'related value': other,
                 'related objects': other_count, 'example ids': ' '.join(list(ids)[:4]), 'suggestion': suggestion})


for field in FIELDS:
    counts, ids = Counter(), defaultdict(list)
    for o in objects:
        for term in o[field].split(';'):
            term = term.strip()
            if term:
                counts[term] += 1
                ids[term].append(o['objectid'])

    for term, n in sorted(counts.items(), key=lambda kv: (-kv[1], kv[0])):
        if re.search(r'<[^>]+>', term):
            clean = re.sub(r'\s+', ' ', re.sub(r'</P>\s*<P>', '; ', re.sub(r'</?P>', '', term, flags=re.I))).strip()
            add('markup in value', field, term, n, ids=ids[term],
                suggestion='remove the <P> tags' + (f'; as separate terms: {clean}' if '; ' in clean else ''))

    # the same term written differently (case, hyphen, spacing, stray brackets), ignoring uncertainty marks
    groups = defaultdict(list)
    for term in counts:
        groups[norm(term)].append(term)
    for forms in groups.values():
        spellings = defaultdict(list)
        for term in forms:
            spellings[base(term)].append(term)
        if len(spellings) > 1:
            best = max(spellings, key=lambda s: sum(counts[t] for t in spellings[s]))
            for s, terms in spellings.items():
                if s != best:
                    add('same term, different spelling', field, s, sum(counts[t] for t in terms), best,
                        sum(counts[t] for t in spellings[best]), [i for t in terms for i in ids[t]],
                        f'use one spelling, probably "{best}"')

    # uncertainty marked in several ways, or the term also occurs without a mark
    by_base = defaultdict(list)
    for term in counts:
        by_base[base(term)].append(term)
    for b, terms in by_base.items():
        marked = [t for t in terms if uncertain(t)]
        for t in marked:
            plain = [x for x in terms if not uncertain(x)]
            add('uncertainty written into the value', field, t, counts[t],
                plain[0] if plain else '', counts[plain[0]] if plain else '', ids[t],
                'decide on one convention for uncertain values; a "?" suffix, " (?)" and "(?)" inside the term all occur')

    # abbreviations and slashes in period-like fields
    if field in ('period', 'style', 'ceramic_phase'):
        for term, n in counts.items():
            if re.search(r'\b\w{2,}\.(?=\W|$)', term) and not re.search(r'\b[A-Z]\.[A-Z]\.', term):
                add('abbreviation', field, term, n, ids=ids[term], suggestion='spell out (e.g. "Clas." as "Classical")')
            elif '/' in term and not re.search(r'\b\w{2,}\.', term):
                add('several values in one term', field, term, n, ids=ids[term],
                    suggestion='keep as one value, or split into separate terms with ";"')

    # stray characters (markup and abbreviations are reported above)
    for term, n in counts.items():
        if re.search(r'<[^>]+>', term):
            continue
        if re.search(r'[\x80-\x9f]|[\[\]{}]|^[^\w(]|[,:;]$', term):
            add('stray character', field, term, n, ids=ids[term], suggestion='check for a typo or stray punctuation')

    # a rare term that is almost the same as a commoner one (a possible typo)
    common = [t for t in counts if counts[t] >= 3]
    for term in counts:
        if counts[term] > 2 or uncertain(term) or '<' in term:
            continue
        for other in common:
            if other == term or norm(other) == norm(term) or re.search(r'\d|\b[IVX]+\b', term) or re.search(r'\d|\b[IVX]+\b', other):
                continue
            # words that differ only in a short token (a letter, "S." and "W.") are different terms, not typos
            diff = [w for w in set(term.lower().split()) ^ set(other.lower().split())]
            if diff and all(len(w.strip('().,')) <= 2 for w in diff):
                continue
            if difflib.SequenceMatcher(None, term.lower(), other.lower()).ratio() >= .92:
                add('possible typo', field, term, counts[term], other, counts[other], ids[term],
                    'review: a misspelling or variant spelling of the related value? (many of these will be fine)')
                break

# facet fields named in the configuration that are not columns of the data
for field in ('site',):
    if field not in objects[0]:
        add('no such column', field, '', 0, suggestion='the site configuration lists this field, but the data has no such column (our side, not Airtable)')

order = {k: i for i, k in enumerate(['markup in value', 'same term, different spelling', 'stray character', 'possible typo',
                                      'abbreviation', 'several values in one term', 'uncertainty written into the value', 'no such column'])}
rows.sort(key=lambda r: (order[r['issue']], r['field'], -int(r['objects'] or 0), r['value']))
with open(OUT, 'w', newline='', encoding='utf-8') as fh:
    w = csv.DictWriter(fh, fieldnames=['issue', 'field', 'value', 'objects', 'related value', 'related objects', 'example ids', 'suggestion'])
    w.writeheader()
    w.writerows(rows)
c = Counter(r['issue'] for r in rows)
print(f'{len(rows)} rows written to {OUT}')
for k in order:
    print(f'  {c[k]:4}  {k}')

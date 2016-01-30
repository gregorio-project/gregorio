# Stem length configuration for squarize.py

def get_default_porrectus(font_config):
    return {
            "Nothing": {
              "1": {
                "short": font_config['bottom-porrectus-1'],
                "long": font_config['bottom-porrectus-1-long']
              },
              "2": {
                "short": font_config['bottom-porrectus-2']
              },
              "3": {
                "short": font_config['bottom-porrectus-3']
              },
              "4": {
                "short": font_config['bottom-porrectus-4']
              },
              "5": {
                "short": font_config['bottom-porrectus-5']
              }
            }
        }

def get_conf(font_config, bmu, suffix, add_suppl, second_suffix=''):
    suffixed = bmu+'-'+suffix
    second_suffixed = bmu+'-'+suffix+'-'+second_suffix
    base = font_config[bmu]
    if second_suffixed in font_config:
        base = font_config[second_suffixed]
    elif suffixed in font_config:
        base = font_config[suffixed]
    if add_suppl and bmu == 'bottom':
        base += font_config['bottom-add']
    return base

def get_stem_schema_default(font_config):

    bh = font_config['base height']

    def get_basic(suffix, add_suppl=False, second_suffix=''):
        bottom = get_conf(font_config, 'bottom', suffix, add_suppl, second_suffix)
        middle = get_conf(font_config, 'middle', suffix, add_suppl, second_suffix)
        top    = get_conf(font_config, 'top', suffix, add_suppl, second_suffix)
        # using lower version for bottom of quilisma when second is on a line
        bottom_lower    = get_conf(font_config, 'bottom', suffix, add_suppl, 'lower')
        # for ambitus one, it must have the same height as the virga for coherece, so ignoing suffix
        bottom_one = get_conf(font_config, 'bottom', '', add_suppl, second_suffix)
        return {
              "1": {
                # ignoring the suffix for coherence
                "short": bottom_one - 2*bh,
                "long": bottom_one - bh,
                "open": bottom_one - bh
              },
              "2": {
                "short": bottom - 2*bh,
                "long": bottom_lower - 2*bh
              },
              "3": {
                "short": middle - 3*bh,
                "long": bottom_lower - 3*bh
              },
              "4": {
                "short": top - 4*bh,
                "long": top - 4*bh
              },
              "5": {
                "short": top - 5*bh,
                "long": top - 4*bh
              }
            }

    bottom_virga = get_conf(font_config, 'bottom', '', False)

    return {
          "ignore j": False,
          "Virga": {
            "Nothing": {
              "short": bottom_virga - bh,
              "open": bottom_virga - bh,
              "long": bottom_virga - 2*bh
            }
          },
          "Flexus": {
            "Nothing": get_basic(''),
            "Deminutus": {
              "1": {
                "short": font_config['top'] - 3*bh,
                "long": font_config['middle'] - 2*bh,
                "open": font_config['bottom-deminutus'] - bh
              },
              "2": {
                "short": font_config['bottom'] -2*bh,
                "long": font_config['bottom'] - 2*bh,
              },
              "3": {
                "long": font_config['top-deminutus'] - 3*bh,
                "short": font_config['top'] - 3*bh
              },
              "4": {
                "long": font_config['top-deminutus'] - 4*bh,
                "short": font_config['top-deminutus'] - 4*bh,
              },
              "5": {
                "long": font_config['bottom'] - 3*bh,
                "short": font_config['top-deminutus'] - 5*bh,
              }
            }
          },
          "PesQuilismaQuadratum": {
            "Nothing": get_basic('quilisma', False, 'upper')
          },
          "PesQuassus": {
            "Nothing": get_basic('oriscus', False)
          },
          "Porrectus": get_default_porrectus(font_config)
        }

def get_stem_schema_solesmes(font_config):

    bh = font_config['base height']

    def get_bottom(suffix, add_suppl=True, second_suffix=''):
        return get_conf(font_config, 'bottom', suffix, add_suppl, second_suffix)

    def get_basic(suffix, add_suppl=True, second_suffix=''):
        bottom = get_bottom(suffix, add_suppl, second_suffix)
        # for ambitus one, it must have the same height as the virga for coherece, so ignoing suffix
        bottom_one = get_bottom('', add_suppl, second_suffix)
        return {
              "1": {
                "short": bottom_one - 2*bh,
                "long": bottom_one - bh,
                "open": bottom_one - bh
              },
              "2": {
                "short": bottom - 2*bh,
                "long": bottom - 2*bh
              },
              "3": {
                "short": bottom - 3*bh,
                "long": bottom - 3*bh
              },
              "4": {
                "short": bottom - 4*bh,
                "long": bottom - 4*bh
              },
              "5": {
                "short": bottom - 5*bh,
                "long": bottom - 5*bh
              }
            }
    bottom_virga = get_bottom('')
    return {
          "ignore j": True,
          "Virga": {
            "Nothing": {
              "short": bottom_virga - bh,
              "open": bottom_virga - bh,
              "long": bottom_virga - 2*bh
            }
          },
          "Flexus": {
            "Nothing": get_basic(''),
            "Deminutus": get_basic('')
          },
          "PesQuilismaQuadratum": {
            "Nothing": get_basic('quilisma', False, 'lower')
          },
          "PesQuassus": {
            "Nothing": get_basic('oriscus', False)
          },
          "Porrectus": get_default_porrectus(font_config)
        }

def get_stem_schema(schemaname, font_config):
    if schemaname == 'default':
        return get_stem_schema_default(font_config)
    elif schemaname == 'solesmes':
        return get_stem_schema_solesmes(font_config)
    print('impossible to find schema %s, quitting' % schemaname)

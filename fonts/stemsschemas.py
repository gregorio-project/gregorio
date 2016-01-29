# Stem length configuration for squarize.py

def get_stem_schema_default(font_config):
    return {
          "ignore j": False,
          "Virga": {
            "Nothing": {
              "short": font_config['middle']-2*font_config['base height'],
              "open": font_config['bottom']-font_config['base height'],
              "long": font_config['bottom']-2*font_config['base height']
            }
          },
          "Flexus": {
            "Nothing": {
              "1": {
                "short": font_config['bottom']-2*font_config['base height'],
                "long": font_config['bottom']-1*font_config['base height'],
                "open": font_config['bottom']-1*font_config['base height']
              },
              "2": {
                "short": font_config['bottom']-2*font_config['base height'],
                "long": font_config['bottom']-2*font_config['base height']
              },
              "3": {
                "short": font_config['middle']-3*font_config['base height'],
                "long": font_config['top']-4*font_config['base height']
              },
              "4": {
                "short": font_config['top']-4*font_config['base height'],
                "long": font_config['top']-4*font_config['base height']
              },
              "5": {
                "short": font_config['top']-5*font_config['base height'],
                "long": font_config['top']-4*font_config['base height']
              }
            },
            "Deminutus": {
              "1": {
                "short": font_config['top']-3*font_config['base height'],
                "long": font_config['middle']-2*font_config['base height'],
                "open": font_config['bottom-deminutus']-font_config['base height']
              },
              "2": {
                "short": font_config['bottom']-2*font_config['base height'],
                "long": font_config['bottom']-2*font_config['base height'],
              },
              "3": {
                "long": font_config['top-deminutus']-3*font_config['base height'],
                "short": font_config['top']-3*font_config['base height']
              },
              "4": {
                "long": font_config['top-deminutus']-4*font_config['base height'],
                "short": font_config['top-deminutus']-4*font_config['base height'],
              },
              "5": {
                "long": font_config['bottom']-3*font_config['base height'],
                "short": font_config['top-deminutus']-5*font_config['base height'],
              }
            }
          },
          "Porrectus": {
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
        }

def get_stem_schema(schemaname, font_config):
    if schemaname == 'default':
        return get_stem_schema_default(font_config)
    print('impossible to find schema %s, quitting' % schemaname)

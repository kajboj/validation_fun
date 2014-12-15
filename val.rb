pp_hash = {
  'price_policy' => {
    'tiers' => [
      {
        'conditions' => {
          'basket_value' => { 'from' => 3, 'to' => 5 },
          'distance' => { 'from' => 0, 'to' => 100 }
        },
        'tariff_id' => 3
      }
    ]
  }
}

def hash; end
def allowed_keys(keys); end
def nested_hash(key); end
def nested_array(key); end
def from_to(key); end
def tariff_id(key, merchant); end

def apply(*args); end
def sequence(*args); end
def each(key, validator); end

def merchant; end

sequence(
  hash,
  allowed_keys(['price_policy']),
  nested_hash('price_policy'),
  allowed_keys(['tiers']),
  nested_array('tiers'),
  each('tiers', sequence(
    hash,
    allowed_keys(['conditions', 'tariff_id']),
    apply(
      sequence(
        nested_hash('conditions'),
        allowed_keys(['basket_value', 'distance']),
        apply(
          from_to('basket_value'),
          from_to('distance'))),
      tariff_id('tariff_id', merchant)))))

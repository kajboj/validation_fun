def hash(msg = 'must be a hash')
  lambda do |h|
    if h.is_a?(Hash)
      [h, {}]
    else
      [{}, {'base' => [msg]}]
    end
  end
end

def allowed_keys(allowed_keys, msg = 'not allowed')
  lambda do |h|
    errors = {}

    h.keys.each do |key|
      if !allowed_keys.include?(key)
        errors[key] = [msg]
      end
    end

    [h, errors]
  end
end

def nested_hash(key, msg = 'must be a hash')
  nested(Hash, key, msg)
end

def nested_array(key, msg = 'must be an array')
  nested(Array, key, msg)
end

def nested(type, key, msg)
  lambda do |h|
    if h[key].is_a?(type)
      [h[key], {}]
    else
      [{}, {key => [msg]}]
    end
  end
end

def from_to(key); end
def tariff_id(key, merchant); end


def apply(*args); end

def sequence(*validators)
  lambda do |validated_object|
    validators.inject([validated_object, {}]) do |(object, errors), validator|
      new_object, new_errors = validator.call(object)
      [new_object, merge(errors, new_errors)]
    end
  end
end

def merge(e1, e2)
  (e1.keys + e2.keys).inject({}) do |e, k|
    e[k] = (e1[k] || []) + (e2[k] || [])
    e
  end
end

def each(key, validator)
end

def merchant; end

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

v = sequence(
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

v = sequence(
  hash,
  allowed_keys(%w(price_policy)),
  nested_hash('price_policy'),
  allowed_keys(%w(tiers)),
  nested_array('tiers')
)

puts v.call({
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
})

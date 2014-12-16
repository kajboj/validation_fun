def hash(*validators)
  lambda do |h, errors, prefix|
    if h.is_a?(Hash)
      all(*validators).call(h, errors, prefix)
    else
      [{}, merge(errors, {join(prefix, 'base') => ['must be a hash']})]
    end
  end
end

def allowed_keys(allowed_keys)
  lambda do |h, errors, prefix|
    new_errors = {}

    h.keys.each do |key|
      if !allowed_keys.include?(key)
        new_errors[key] = ['not allowed']
      end
    end

    [h, merge(errors, new_errors)]
  end
end

def nested_hash(key, *validators)
  lambda do |h, errors, prefix|
    if h[key].is_a?(Hash)
      all(*validators).call(h[key], errors, prefix)
    else
      [{}, {join(prefix, key) => ['must be a hash']}]
    end
  end
end

def nested_array(key, msg = 'must be an array')
end

def from_to(key); end
def tariff_id(key, merchant); end


def all(*validators)
  lambda do |object, errors, prefix|
    [
      object,
      validators.inject(errors) do |errs, validator|
        o, new_errors = validator.call(object, errs, prefix)
        merge(errs, new_errors)
      end
    ]
  end
end

def required(key)
  lambda do |hash, errors, prefix|
    if hash.has_key?(key)
      [hash, errors]
    else
      errors[join(prefix, key)]
      [hash, error]
    end
  end
end

def merge(e1, e2)
  (e1.keys + e2.keys).inject({}) do |e, k|
    e[k] = (e1[k] || []) + (e2[k] || [])
    e
  end
end

def join(prefix, segment)
  [prefix, segment].compact.join('/')
end

def each(key, validator)
end

def merchant; end

v = hash(
  allowed_keys(['price_policy']),
  nested_hash('price_policy',
    allowed_keys(['tiers']),
    nested_array('tiers',
      hash(
        allowed_keys(['conditions', 'tariff_id']),
        nested_hash('conditions',
          allowed_keys(['basket_value', 'distance']),
          from_to('basket_value'),
          from_to('distance')),
        tariff_id('tariff_id', merchant)))))

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

w = hash(
  allowed_keys(['price_policy']),
  nested_hash('price_policy')
)

h = {
  'a' => 'x'
}

puts w.call(h, {}, nil)

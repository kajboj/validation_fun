def hash(*validators)
  lambda do |h, errors, prefix|
    if h.is_a?(Hash)
      all(*validators).call(h, errors, prefix)
    else
      [h, merge(errors, {prefix => ['must be a hash']})]
    end
  end
end

def allowed_keys(allowed_keys)
  lambda do |h, errors, prefix|
    new_errors = {}

    h.keys.each do |key|
      if !allowed_keys.include?(key)
        new_errors[join(prefix, key)] = ['not allowed']
      end
    end

    [h, merge(errors, new_errors)]
  end
end

def nested_hash(key, *validators)
  lambda do |h, errors, prefix|
    if h[key].is_a?(Hash)
      all(*validators).call(h[key], errors, join(prefix, key))
    else
      [h[key], merge(errors, {join(prefix, key) => ['must be a hash']})]
    end
  end
end

def nested_array(key, validator = lambda {})
  lambda do |h, errors, prefix|
    if h[key].is_a?(Array)
      result_object, result_errors = [], errors
      h[key].each.with_index do |object, index|
        new_object, new_errors = validator.call(object, errors, join(prefix, index))
        result_object << new_object
        result_errors = merge(result_errors, new_errors)
      end
      [result_object, result_errors]
    else
      [h[key], merge(errors, {join(prefix, key) => ['must be an array']})]
    end
  end
end

def integer(key)
  lambda do |h, errors, prefix|
    begin
      i = Integer(h[key])
      h[key] = i
      [h, errors]
    rescue ArgumentError
      [h, merge(errors, {join(prefix, key) => ['must be an integer']})]
    end
  end
end

def from_to(key)
  nested_hash(key,
    integer('from'),
    integer('to')
  )
end

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
    e[k] = ((e1[k] || []) + (e2[k] || [])).uniq
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
  nested_hash('price_policy',
    allowed_keys(['tiers']),
    nested_array('tiers',
      hash(
        allowed_keys(['conditions', 'tariff_id']),
        nested_hash('conditions',
          allowed_keys(['basket_value', 'distance']),
          from_to('basket_value'),
          from_to('basket_value')
        )
      )
    )
  )
)

h = {
  'price_policy' => {
    'tiers' => [
      {
        'conditions' => {
          'basket_value' => {
            'from' => 'hello',
            'to'   => 5
          }
        },
        'tariff_id'  => 'world'
      }
    ]
  }
}

puts w.call(h, {}, nil)
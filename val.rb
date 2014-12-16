def hash(*validators)
  lambda do |h, errors, prefix|
    if h.is_a?(Hash)
      all(*validators).call(h, errors, prefix)
    else
      add(errors, 'must be a hash', prefix)
      false
    end
  end
end

def allowed_keys(allowed_keys)
  lambda do |h, errors, prefix|
    h.keys.inject(true) do |b, key|
      if !allowed_keys.include?(key)
        add(errors, 'not allowed', prefix, key)
        false
      else
        b && true
      end
    end
  end
end

def nested_hash(key, *validators)
  lambda do |h, errors, prefix|
    if h[key].is_a?(Hash)
      all(*validators).call(h[key], errors, join(prefix, key))
    else
      add(errors, key, 'must be a hash')
      false
    end
  end
end

def nested_array(key, validator = lambda {})
  lambda do |h, errors, prefix|
    if h[key].is_a?(Array)
      h[key].each.with_index do |object, index|
        validator.call(object, errors, join(prefix, index))
        result_object << new_object
        result_errors = merge(result_errors, new_errors)
      end
      [result_object, result_errors]
    else
      add(errors, key, 'must be an array')
      false
    end
  end
end

def integer(key)
  lambda do |h, errors, prefix|
    begin
      i = Integer(h[key])
      h[key] = i
      [h, errors]
    rescue ArgumentError, TypeError
      [h, merge(errors, {join(prefix, key) => ['must be an integer']})]
    end
  end
end

def from_to(key)
  first_failure(
    nested_hash(key,
      allowed_keys(['from', 'to']),
      integer('from'),
      integer('to')
    ),
    lambda do |h, errors, prefix|
      if h[key]['from'] > h[key]['to']
        [h, merge(errors, {join(prefix, key, 'to') => ['must be greater or equal from']})]
      else
        [h, errors]
      end
    end
  )
end

def tariff_id(key, merchant); end

def all(*validators)
  lambda do |object, errors, prefix|
    validators.inject(true) do |b, validator|
      r = validator.call(object, errs, prefix)
      b && r
    end
  end
end

def first_failure(*validators)
  lambda do |object, errors, prefix|
    count = count_errors(errors)
    [
      object,
      validators.each do |validator|
        o, new_errors = validator.call(object, errors, prefix)
        if count < count_errors(new_errors)
          return [o, new_errors]
        end
      end
    ]
  end
end

def add(errors, msg, *segments)
  merge(errors, {join(*segments) => [msg]})
end

def merge(e1, e2)
  (e1.keys + e2.keys).inject({}) do |e, k|
    e[k] = ((e1[k] || []) + (e2[k] || [])).uniq
    e
  end
end

def count_errors(e)
  e.inject(0) do |count, (_, v)|
    count + v.size
  end
end

def join(*segments)
  segments.compact.join('/')
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
          from_to('basket_value')
          # from_to('distance')
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
            'from' => 7,
            'to'   => '12'
          },
          'distance' => {
            'from' => 1,
            'to'   => 2
          }
        },
        'tariff_id'  => 'world'
      }
    ]
  }
}

require 'json'
puts JSON.pretty_generate(w.call(h, {}, nil))

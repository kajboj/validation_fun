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
      add(errors, 'must be a hash', prefix, key)
      false
    end
  end
end

def nested_array(key, validator = lambda {})
  lambda do |h, errors, prefix|
    if h[key].is_a?(Array)
      h[key].inject([true, 0]) do |(acc, index), array|
        b = validator.call(array, errors, join(prefix, index))
        [acc && b, index+1]
      end.first
    else
      add(errors, 'must be an array', prefix, key)
      false
    end
  end
end

def integer(key)
  lambda do |h, errors, prefix|
    begin
      i = Integer(h[key])
      h[key] = i
      true
    rescue ArgumentError, TypeError
      add(errors, 'must be an integer', prefix, key)
      false
    end
  end
end

def from_to(key)
  first_failure(
    nested_hash(key,
      allowed_keys(['from', 'to']),
      first_failure(
        required('from'),
        integer('from')
      ),
      first_failure(
        required('to'),
        integer('to')
      )
    ),
    lambda do |h, errors, prefix|
      if h[key]['from'] > h[key]['to']
        add(errors, 'must be greater or equal \'from\'', prefix, key, 'to')
        false
      else
        true
      end
    end
  )
end

def tariff_id(key)
  lambda do |h, errors, prefix|
    true
  end
end

def all(*validators)
  lambda do |object, errors, prefix|
    validators.inject(true) do |acc, validator|
      r = validator.call(object, errors, prefix)
      acc && r
    end
  end
end

def required(key)
  lambda do |h, errors, prefix|
    if !h.has_key?(key)
      add(errors, 'is required', prefix, key)
      false
    else
      true
    end
  end
end

def first_failure(*validators)
  lambda do |object, errors, prefix|
    validators.each do |validator|
      if !validator.call(object, errors, prefix)
        return false
      end
    end
    true
  end
end

def add(errors, msg, *segments)
  merge(errors, {join(*segments) => [msg]})
end

def merge(e1, e2)
  e2.keys.each do |k, v|
    e1[k] = ((e1[k] || []) + (e2[k] || [])).uniq
  end
end

def join(*segments)
  segments.compact.join('/')
end

w = hash(
  allowed_keys(['price_policy']),
  required('price_policy'),
  nested_hash('price_policy',
    allowed_keys(['tiers']),
    nested_array('tiers',
      hash(
        allowed_keys(['conditions', 'tariff_id']),
        nested_hash('conditions',
          allowed_keys(['basket_value', 'distance']),
          from_to('basket_value'),
          from_to('distance')
        ),
        tariff_id('tariff_id')
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
            'from' => 17,
            'to'   => '12'
          },
          'distance' => {
            'from' => 1
          }
        },
        'tariff_id'  => 'world'
      }
    ]
  }
}

errors = {}

puts w.call(h, errors, nil)

require 'json'
puts JSON.pretty_generate(h)
puts JSON.pretty_generate(errors)


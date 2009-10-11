unless ERBook.const_defined? :INOCHI
  fail "ERBook must be established by Inochi"
end

ERBook::INOCHI.each do |param, value|
  const = param.to_s.upcase

  unless ERBook.const_defined? const
    fail "ERBook::#{const} must be established by Inochi"
  end

  unless ERBook.const_get(const) == value
    fail "ERBook::#{const} is not what Inochi established"
  end
end

puts "Inochi establishment tests passed!"

# Loop samples

def for_samples
  for foo in bar
  end

  for foo, bar in baz
  end

  for foo, in bar
  end
end

# begin..end in conditions
#
def while_until_samples
  while begin foo end
    bar
  end

  until begin foo end
    bar
  end

  while begin foo end do
    bar
  end

  until begin foo end do
    bar
  end

  foo while begin bar end

  foo until begin bar end
end

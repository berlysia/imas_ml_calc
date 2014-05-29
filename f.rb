cards = [
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955],
  [10935,7955]
]

supports = [
  [10910,7980],
  [10910,7980],
  [10910,7980],
  [10910,7980],
  [10910,7980],
  [10910,7980],
  [5802,5298]
]

skills = [
  [0.28,0.28],
  [0.28,0.28],
  [0.28,0.28],
  [0.28,0.28]
]

renkei = [
  [0.02,0],
  [0.01,0.01],
  [0.03,0]
]

shinai = 0.0825

rounge = 0.02

def calc(cards,supports,skills,renkei,shinai,rounge)
  ret = cards.map{|c|
    sum = [0,0]
    2.times do |i|
      base = c[i]+(c[i]*shinai).ceil
      foo = base
      foo += skills.map{|s|(base*s[i]).floor}.reduce :+
      foo += renkei.map{|s|(base*s[i]).floor}.reduce :+
      foo += (base*rounge).floor
      sum[i] = foo
    end
    sum
  }.transpose.map{|r|r.reduce :+}.reduce :+

  ret += supports.transpose.map{|r|r.map{|a|(a*0.8).floor}.reduce :+}.reduce :+

  ret
end

puts calc(cards,supports,skills,renkei,shinai,rounge)

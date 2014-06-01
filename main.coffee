basePath = "http://berlysia.github.io/imas_ml/stat/millionlive_"

effectFactory = (base,step) ->
  (level)->
    level -= if level<10 then 1 else 0
    base + step * level

irregularEffect = (base,step) ->
  (level)->
    level -= 1 if level<3
    level += 1 if 10<=level
    base + step * level

effectBoard =
  self:
    one:
      1: effectFactory(0.18,0.09)
      2: effectFactory(0.36,0.09)
      3: effectFactory(0.72,0.09)
      4: effectFactory(0,0)
    both:
      1: effectFactory(0.09,0.045)
      2: effectFactory(0.18,0.045)
      3: effectFactory(0.36,0.045)
      4: effectFactory(0,0)
  singleRegion:
    one:
      1: effectFactory(0.05,0.01)
      2: effectFactory(0.10,0.01)
      3: effectFactory(0.13,0.01)
      4: irregularEffect(0.15,0.01)
    both:
      1: effectFactory(0.02,0.01)
      2: effectFactory(0.04,0.01)
      3: effectFactory(0.08,0.01)
      4: effectFactory(0.12,0.01)
  allRegion:
    one:
      1: effectFactory(0.02,0.01)
      2: effectFactory(0.04,0.01)
      3: effectFactory(0.08,0.01)
      4: effectFactory()
    both:
      1: effectFactory(0.01,0.01)
      2: effectFactory(0.02,0.01)
      3: effectFactory()
      4: effectFactory()

effectParse = (serial,target)->
  switch target
    when "other"
      return (serial>>13)&1
    when "vocal"
      return (serial>>12)&1
    when "dance"
      return (serial>>11)&1
    when "visual"
      return (serial>>10)&1
    when "targetPlayer"
      return (serial>>9)&1
    when "targetArea"
      return (serial>>6)&7
    when "apActive"
      return (serial>>5)&1
    when "dpActive"
      return (serial>>4)&1
    when "upOrDown"
      return (serial>>3)&1
    when "scale"
      return serial&7
    else
      return null

getEffect = (serial,level) ->
  return {ap:0, dp:0} if level < 1 || 20 < level
  if effectParse(serial,"other")==1 || effectParse(serial,"targetPlayer")==0 || effectParse(serial,"upOrDown")==0
    console.log "rejected",effectParse(serial,"other"),effectParse(serial,"targetPlayer"),effectParse(serial,"upOrDown")
    return {ap:0, dp:0}
  else
    target = []
    if (effectParse(serial,"vocal") & effectParse(serial,"dance") & effectParse(serial,"visual")) == 0
      firstKey = "singleRegion" # 今のところはこれでよい
      target.push "Vo" if effectParse(serial,"vocal")==1
      target.push "Da" if effectParse(serial,"dance")==1
      target.push "Vi" if effectParse(serial,"visual")==1
    else if effectParse(serial,"targetArea") == 2
      firstKey = "allRegion"
      target.concat ["Vo","Da","Vi"]
    else if effectParse(serial,"targetArea") == 7
      firstKey = "self"
      target.push "self"
    else
      console.log "othercase"
      return {ap:0, dp:0}

    secondKey = if (effectParse(serial,"apActive")&effectParse(serial,"dpActive")) then "both" else "one"

    eff = effectBoard[firstKey][secondKey][effectParse(serial,"scale")](level) || [0]
    if secondKey == "both"
      return {ap:eff, dp:eff, target:target}
    else
      return {ap:eff, dp:0, target:target} if effectParse(serial,"apActive")==1
      return {ap:0, dp:eff, target:target} if effectParse(serial,"dpActive")==1
      return {ap:0, dp:0}

class Idol
  constructor: (@id,@name,@region,@cost,@ap,@dp,@skill_name,@skill_type,@skill_serialized)->
    @skill_level = 20
    @shinai = 500
    @ap = parseInt(@ap)
    @dp = parseInt(@dp)
    @cost = parseInt(@cost)
    if @id == 1e5
      @skill_serialized = 1e5
    @skill_effect = getEffect(@skill_serialized,@skill_level)
    @skill_activated = false
    @editable = @id == 1e5
    @renkei_0 = false
    @renkei_1 = false
    @renkei_2 = false

content = $ ->
  view = new Vue
    el: "#calc"
    data:
      roungeBonus:
        ap: 0.02
        dp: 0.02
      renkei:[
        {ap: 0.03, dp: 0},
        {ap: 0.01, dp: 0.01},
        {ap: 0.02, dp: 0}
      ]
      idolList: {}
      activeIDs: []
      activeNames: []
      loaded: []
      frontMember: []
      supportMember: []
      idolFactory:
        region: "--"
        rarity: "--"
        id: 1e5
      result:
        front: []
        support: []
        sumAud: 0
        sumFes: 0
    computed:
      percost: ->
        @$data.supportMember.map (idol)-> ((parseInt(idol.ap)+parseInt(idol.dp))/idol.cost).toFixed(2)
    methods:
      preload: (reg,rar)->
        prop = reg+"_"+rar
        console.log @$data.loaded, reg, rar
        unless prop of @$data.loaded
          return $.get(basePath+prop+".json")
            .then (d,s)=>
              console.log "loaded:", s, d
              @$data.loaded.push prop
              @$data.activeIDs = []
              @$data.activeNames = []
              for id, idol of d
                @$data.activeIDs.push id
                @$data.activeNames.push idol["カード名"]
                @$data.idolList[id] = new Idol(
                  idol["カードID"],
                  idol["カード名"],
                  idol["属性"],
                  idol["コスト"],
                  idol["MAX AP"],
                  idol["MAX DP"],
                  idol["スキル"],
                  idol["効果"],
                  idol["skill_serialized"],
                  )
        else
          return $.Deferred()

      preloadByFormChange: ->
        console.log "formchange detected"
        reg = @$data.idolFactory.region
        rar = @$data.idolFactory.rarity
        return if reg=="--" || rar=="--"
        @preload(reg,rar)

      addIdol: (id,isSupport)->
        console.log id, @$data.idolList[id]
        member = if isSupport then @$data.supportMember else @$data.frontMember
        tmp = null
        if typeof @$data.idolList[id] != "undefined"
          tmp = $.extend(true,new Idol(),@$data.idolList[id])
        else
          tmp = new Idol(1e5)
        member.push tmp
        @
      removeIdol: (idx,isSupport)->
        member = if isSupport then @$data.supportMember else @$data.frontMember
        member.$remove(idx)
        @
      moveUpIdol: (idx,reverse,isSupport)->
        member = if isSupport then @$data.supportMember else @$data.frontMember
        tmp = member.$remove(idx)
        member.splice idx + (if reverse then 1 else -1),0,tmp
        @
      calc: ->
        front = []# @$data.result.front
        support = []# @$data.result.support

        for i,idol of @$data.frontMember
          shinai = 0
          shinai = 0.05 if 100 <= parseInt(idol.shinai)
          shinai = 0.06 if 200 <= parseInt(idol.shinai)
          shinai = 0.07 if 300 <= parseInt(idol.shinai)
          shinai = 0.0775 if 400 <= parseInt(idol.shinai)
          shinai = 0.0825 if 500 <= parseInt(idol.shinai)
          
          baseAP = parseInt(idol.ap) + Math.ceil(parseInt(idol.ap) * shinai)
          baseDP = parseInt(idol.dp) + Math.ceil(parseInt(idol.dp) * shinai)
          incAP = Math.floor(baseAP * parseFloat(@$data.roungeBonus.ap))
          incDP = Math.floor(baseDP * parseFloat(@$data.roungeBonus.dp))

          for j,ren of @$data.renkei
            continue unless idol["renkei_"+j]
            incAP += Math.floor(baseAP * parseFloat(ren.ap))
            incDP += Math.floor(baseDP * parseFloat(ren.dp))

          front[i] = {
            baseAP:baseAP
            baseDP:baseDP
            incAP:incAP
            incDP:incDP
          }

        for i,idol_i of @$data.frontMember
          eff = idol_i.skill_effect
          console.log eff.target
          for j,idol_j of @$data.frontMember
            continue unless idol_j.skill_activated
            continue unless eff.target?
            continue if "self" in eff.target && i != j
            continue unless idol_j.region in eff.target
            front[j].incAP += Math.floor(front[j].baseAP * eff.ap)
            front[j].incDP += Math.floor(front[j].baseDP * eff.dp)

        for i,idol of @$data.supportMember
          support[i] = {
            ap: Math.floor(parseInt(idol.ap) * 0.8)
            dp: Math.floor(parseInt(idol.dp) * 0.8)
          }

        # console.log front.map (f)-> [f.baseAP,f.incAP]
        # console.log support.map (s)-> s.ap

        @$data.result.front = front
        @$data.result.support = support

        sumAud = 0
        sumFes = 0
        for i,obj of front
          sumAud += obj.baseAP
          sumAud += obj.baseDP
          sumAud += obj.incAP
          sumAud += obj.incDP
          sumFes += obj.incAP
          sumFes += obj.baseAP
        for i,obj of support
          sumAud += obj.ap
          sumAud += obj.dp
        @$data.result.sumAud = sumAud
        @$data.result.sumFes = sumFes

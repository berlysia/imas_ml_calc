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
    # console.log "rejected",effectParse(serial,"other"),effectParse(serial,"targetPlayer"),effectParse(serial,"upOrDown")
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
      # console.log "othercase"
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
      supportCostLimit: 130
      idolFactory:
        region: "--"
        rarity: "--"
        id: 1e5
      result:
        front: []
        support: []
        detail: ""
        sumAud: 0
        sumAudInIMC: 0
        sumFes: 0
    computed:
      percost: ->
        @$data.supportMember.map (idol)-> ((parseInt(idol.ap)+parseInt(idol.dp))/idol.cost).toFixed(2)
    methods:
      preload: (reg,rar)->
        prop = reg+"_"+rar
        # console.log @$data.loaded, reg, rar
        unless prop of @$data.loaded
          return $.get(basePath+prop+".json")
            .then (d,s)=>
              # console.log "loaded:", s, d
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
        # console.log "formchange detected"
        reg = @$data.idolFactory.region
        rar = @$data.idolFactory.rarity
        return if reg=="--" || rar=="--"
        @preload(reg,rar)

      renkeiCheckAll: (idx) ->
        # console.log idx
        if (@$data.frontMember.every (idol) -> idol['renkei_'+idx])
          for i,idol of @$data.frontMember
            idol['renkei_'+idx] = false
        else
          for i,idol of @$data.frontMember
            idol['renkei_'+idx] = true
        @

      addIdol: (id,isSupport)->
        # console.log id, @$data.idolList[id]
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

          incByRoungeAP = Math.floor(baseAP * parseFloat(@$data.roungeBonus.ap))
          incByRoungeDP = Math.floor(baseDP * parseFloat(@$data.roungeBonus.dp))

          incByRenkeiAP = [0,0,0]
          incByRenkeiDP = [0,0,0]
          for j,ren of @$data.renkei
            if idol["renkei_"+j]
              incByRenkeiAP[j] += Math.floor(baseAP * parseFloat(ren.ap))
              incByRenkeiDP[j] += Math.floor(baseDP * parseFloat(ren.dp))

          sumOfRenkeiAP = incByRenkeiAP.reduce (a,b)->a+b
          sumOfRenkeiDP = incByRenkeiDP.reduce (a,b)->a+b

          front[i] = {
            name: idol.name
            orgAP: idol.ap
            orgDP: idol.dp
            shinaiBonusAP: Math.ceil(parseInt(idol.ap) * shinai)
            shinaiBonusDP: Math.ceil(parseInt(idol.dp) * shinai)
            baseAP: baseAP
            baseDP: baseDP
            incByRoungeAP: incByRoungeAP
            incByRoungeDP: incByRoungeDP
            incByRenkeiAP: incByRenkeiAP
            incByRenkeiDP: incByRenkeiDP
            incBySkillAP: []
            incBySkillDP: []
            sumOfRenkeiAP: sumOfRenkeiAP
            sumOfRenkeiDP: sumOfRenkeiDP
            sumOfSkillAP: 0
            sumOfSkillDP: 0
          }

        for i,idol_i of @$data.frontMember
          # eff = idol_i.skill_effect
          eff = getEffect(idol_i.skill_serialized,idol_i.skill_level)
          continue unless idol_i.skill_activated
          # console.log eff.target, idol_i.skill_activated
          for j,idol_j of @$data.frontMember
            continue unless eff.target?
            continue if "self" in eff.target && i != j
            continue unless idol_j.region in eff.target
            front[j].incBySkillAP.push([eff,Math.floor(front[j].baseAP * eff.ap)])
            front[j].incBySkillDP.push([eff,Math.floor(front[j].baseDP * eff.dp)])
            front[j].sumOfSkillAP += Math.floor(front[j].baseAP * eff.ap)
            front[j].sumOfSkillDP += Math.floor(front[j].baseDP * eff.dp)

        for i,idol of @$data.supportMember
          support[i] = {
            name: idol.name
            ap: Math.floor(parseInt(idol.ap) * 0.8)
            dp: Math.floor(parseInt(idol.dp) * 0.8)
          }

        @$data.result.front = front
        @$data.result.support = support

        detail = ""

        detail += "-- フロントメンバー\n"

        sumAud = 0
        sumFes = 0
        for i,obj of front
          sumAudTmp = 0
          sumAudTmp += obj.baseAP
          sumAudTmp += obj.baseDP
          sumAudTmp += obj.incByRoungeAP
          sumAudTmp += obj.incByRoungeDP
          sumAudTmp += obj.sumOfRenkeiAP + obj.sumOfRenkeiDP
          sumAudTmp += obj.sumOfSkillAP
          sumAudTmp += obj.sumOfSkillDP
          sumAud += sumAudTmp

          sumFesTmp = 0
          sumFesTmp += obj.sumOfRenkeiAP
          sumFesTmp += obj.sumOfSkillAP
          sumFesTmp += obj.baseAP
          sumFes += sumFesTmp

          detail += "[#{parseInt(i)+1}] #{obj.name}\n"
          detail += "  計算基本AP: #{obj.baseAP}\n"
          detail += "    基礎: #{obj.orgAP} + 親愛: #{obj.shinaiBonusAP}\n"
          detail += "  連携スキル増加分: #{obj.sumOfRenkeiAP}\n"
          for j,val of obj.incByRenkeiAP
            detail += "    + 連携スキル#{(parseInt(j)+1)} x#{@$data.renkei[j].ap}: #{val}\n" if 0<val
          detail += "  固有スキル増加分: #{obj.sumOfSkillAP}\n"
          for j,val of obj.incBySkillAP
            detail += "    + #{val[0].target} x#{val[0].ap}: #{val[1]}\n"
          detail += "-> 合同フェス発揮基準値: #{sumFesTmp}\n"
          detail += "  計算基本DP: #{obj.baseDP}\n"
          detail += "    基礎: #{obj.orgDP} + 親愛: #{obj.shinaiBonusDP}\n"
          detail += "  連携スキル増加分: #{obj.sumOfRenkeiDP}\n"
          for j,val of obj.incByRenkeiDP
            detail += "    + 連携スキル#{(parseInt(j)+1)} x#{@$data.renkei[j].dp}: #{val}\n" if 0<val
          detail += "  固有スキル増加分: #{obj.sumOfSkillDP}\n"
          for j,val of obj.incBySkillDP
            detail += "    + #{val[0].target} x#{val[0].dp}: #{val[1]}\n"
          detail += "  ラウンジボーナスAP: #{obj.incByRoungeAP}\n"
          detail += "  ラウンジボーナスDP: #{obj.incByRoungeDP}\n"
          detail += "-> オーディションバトル発揮値: #{sumAudTmp}\n"
          detail += "  -----  -----  -----  -----  \n"

        detail += "\n-- サポートメンバー\n"
        for i,obj of support
          sumAudTmp = 0
          sumAudTmp += obj.ap
          sumAudTmp += obj.dp
          sumAud += sumAudTmp
          detail += "#{obj.name}: #{obj.ap} + #{obj.dp} = #{sumAudTmp}\n"

        detail += "\n\n"
        detail += "合同フェス発揮基準値（総合）: #{sumFes}\n"
        detail += "オーディションバトル発揮値（総合）: #{sumAud}\n"

        detail += "合同フェス先制アピール参考値\n"
        detail += "BP1: normal->#{parseInt(sumFes)/12}, nice->#{parseInt(sumFes)/6}, perfect->#{parseInt(sumFes)/2}\n"
        detail += "BP2: normal->#{parseInt(sumFes)/20}, nice->#{parseInt(sumFes)/10}, perfect->#{parseInt(sumFes)*3/10}\n"
        detail += "BP3: normal->#{parseInt(sumFes)/24}, nice->#{parseInt(sumFes)/12}, perfect->#{parseInt(sumFes)/4}\n"

        @$data.result.sumAud = sumAud
        @$data.result.sumAudInIMC = Math.ceil(sumAud*1.1)
        @$data.result.sumFes = sumFes
        @$data.result.detail = detail
        # console.log @$data.result.detail

// Generated by CoffeeScript 1.7.1
var Idol, basePath, content, effectBoard, effectFactory, effectParse, getEffect, irregularEffect,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

basePath = "http://berlysia.github.io/imas_ml/stat/millionlive_";

effectFactory = function(base, step) {
  return function(level) {
    level -= level < 10 ? 1 : 0;
    return base + step * level;
  };
};

irregularEffect = function(base, step) {
  return function(level) {
    if (level < 3) {
      level -= 1;
    }
    if (10 <= level) {
      level += 1;
    }
    return base + step * level;
  };
};

effectBoard = {
  self: {
    one: {
      1: effectFactory(0.18, 0.09),
      2: effectFactory(0.36, 0.09),
      3: effectFactory(0.72, 0.09),
      4: effectFactory(0, 0)
    },
    both: {
      1: effectFactory(0.09, 0.045),
      2: effectFactory(0.18, 0.045),
      3: effectFactory(0.36, 0.045),
      4: effectFactory(0, 0)
    }
  },
  singleRegion: {
    one: {
      1: effectFactory(0.05, 0.01),
      2: effectFactory(0.10, 0.01),
      3: effectFactory(0.13, 0.01),
      4: irregularEffect(0.15, 0.01)
    },
    both: {
      1: effectFactory(0.02, 0.01),
      2: effectFactory(0.04, 0.01),
      3: effectFactory(0.08, 0.01),
      4: effectFactory(0.12, 0.01)
    }
  },
  allRegion: {
    one: {
      1: effectFactory(0.02, 0.01),
      2: effectFactory(0.04, 0.01),
      3: effectFactory(0.08, 0.01),
      4: effectFactory()
    },
    both: {
      1: effectFactory(0.01, 0.01),
      2: effectFactory(0.02, 0.01),
      3: effectFactory(),
      4: effectFactory()
    }
  }
};

effectParse = function(serial, target) {
  switch (target) {
    case "other":
      return (serial >> 13) & 1;
    case "vocal":
      return (serial >> 12) & 1;
    case "dance":
      return (serial >> 11) & 1;
    case "visual":
      return (serial >> 10) & 1;
    case "targetPlayer":
      return (serial >> 9) & 1;
    case "targetArea":
      return (serial >> 6) & 7;
    case "apActive":
      return (serial >> 5) & 1;
    case "dpActive":
      return (serial >> 4) & 1;
    case "upOrDown":
      return (serial >> 3) & 1;
    case "scale":
      return serial & 7;
    default:
      return null;
  }
};

getEffect = function(serial, level) {
  var eff, firstKey, secondKey, target;
  if (level < 1 || 20 < level) {
    return {
      ap: 0,
      dp: 0
    };
  }
  if (effectParse(serial, "other") === 1 || effectParse(serial, "targetPlayer") === 0 || effectParse(serial, "upOrDown") === 0) {
    return {
      ap: 0,
      dp: 0
    };
  } else {
    target = [];
    if ((effectParse(serial, "vocal") & effectParse(serial, "dance") & effectParse(serial, "visual")) === 0) {
      firstKey = "singleRegion";
      if (effectParse(serial, "vocal") === 1) {
        target.push("Vo");
      }
      if (effectParse(serial, "dance") === 1) {
        target.push("Da");
      }
      if (effectParse(serial, "visual") === 1) {
        target.push("Vi");
      }
    } else if (effectParse(serial, "targetArea") === 2) {
      firstKey = "allRegion";
      target.concat(["Vo", "Da", "Vi"]);
    } else if (effectParse(serial, "targetArea") === 7) {
      firstKey = "self";
      target.push("self");
    } else {
      return {
        ap: 0,
        dp: 0
      };
    }
    secondKey = effectParse(serial, "apActive") & effectParse(serial, "dpActive") ? "both" : "one";
    eff = effectBoard[firstKey][secondKey][effectParse(serial, "scale")](level) || [0];
    if (secondKey === "both") {
      return {
        ap: eff,
        dp: eff,
        target: target
      };
    } else {
      if (effectParse(serial, "apActive") === 1) {
        return {
          ap: eff,
          dp: 0,
          target: target
        };
      }
      if (effectParse(serial, "dpActive") === 1) {
        return {
          ap: 0,
          dp: eff,
          target: target
        };
      }
      return {
        ap: 0,
        dp: 0
      };
    }
  }
};

Idol = (function() {
  function Idol(id, name, region, cost, ap, dp, skill_name, skill_type, skill_serialized) {
    this.id = id;
    this.name = name;
    this.region = region;
    this.cost = cost;
    this.ap = ap;
    this.dp = dp;
    this.skill_name = skill_name;
    this.skill_type = skill_type;
    this.skill_serialized = skill_serialized;
    this.skill_level = 20;
    this.shinai = 500;
    this.ap = parseInt(this.ap);
    this.dp = parseInt(this.dp);
    this.cost = parseInt(this.cost);
    if (this.id === 1e5) {
      this.skill_serialized = 1e5;
    }
    this.skill_effect = getEffect(this.skill_serialized, this.skill_level);
    this.skill_activated = false;
    this.editable = this.id === 1e5;
    this.renkei_0 = false;
    this.renkei_1 = false;
    this.renkei_2 = false;
  }

  return Idol;

})();

content = $(function() {
  var view;
  return view = new Vue({
    el: "#calc",
    data: {
      roungeBonus: {
        ap: 0.02,
        dp: 0.02
      },
      renkei: [
        {
          ap: 0.03,
          dp: 0
        }, {
          ap: 0.01,
          dp: 0.01
        }, {
          ap: 0.02,
          dp: 0
        }
      ],
      idolList: {},
      activeIDs: [],
      activeNames: [],
      loaded: [],
      frontMember: [],
      supportMember: [],
      supportCostLimit: 130,
      idolFactory: {
        region: "--",
        rarity: "--",
        id: 1e5
      },
      result: {
        front: [],
        support: [],
        detail: "",
        sumAud: 0,
        sumAudInIMC: 0,
        sumFes: 0
      }
    },
    computed: {
      percost: function() {
        return this.$data.supportMember.map(function(idol) {
          return ((parseInt(idol.ap) + parseInt(idol.dp)) / idol.cost).toFixed(2);
        });
      }
    },
    methods: {
      preload: function(reg, rar) {
        var prop;
        prop = reg + "_" + rar;
        if (!(prop in this.$data.loaded)) {
          return $.get(basePath + prop + ".json").then((function(_this) {
            return function(d, s) {
              var id, idol, _results;
              _this.$data.loaded.push(prop);
              _this.$data.activeIDs = [];
              _this.$data.activeNames = [];
              _results = [];
              for (id in d) {
                idol = d[id];
                _this.$data.activeIDs.push(id);
                _this.$data.activeNames.push(idol["カード名"]);
                _results.push(_this.$data.idolList[id] = new Idol(idol["カードID"], idol["カード名"], idol["属性"], idol["コスト"], idol["MAX AP"], idol["MAX DP"], idol["スキル"], idol["効果"], idol["skill_serialized"]));
              }
              return _results;
            };
          })(this));
        } else {
          return $.Deferred();
        }
      },
      preloadByFormChange: function() {
        var rar, reg;
        reg = this.$data.idolFactory.region;
        rar = this.$data.idolFactory.rarity;
        if (reg === "--" || rar === "--") {
          return;
        }
        return this.preload(reg, rar);
      },
      renkeiCheckAll: function(idx) {
        var i, idol, _ref, _ref1;
        if (this.$data.frontMember.every(function(idol) {
          return idol['renkei_' + idx];
        })) {
          _ref = this.$data.frontMember;
          for (i in _ref) {
            idol = _ref[i];
            idol['renkei_' + idx] = false;
          }
        } else {
          _ref1 = this.$data.frontMember;
          for (i in _ref1) {
            idol = _ref1[i];
            idol['renkei_' + idx] = true;
          }
        }
        return this;
      },
      addIdol: function(id, isSupport) {
        var member, tmp;
        member = isSupport ? this.$data.supportMember : this.$data.frontMember;
        tmp = null;
        if (typeof this.$data.idolList[id] !== "undefined") {
          tmp = $.extend(true, new Idol(), this.$data.idolList[id]);
        } else {
          tmp = new Idol(1e5);
        }
        member.push(tmp);
        return this;
      },
      removeIdol: function(idx, isSupport) {
        var member;
        member = isSupport ? this.$data.supportMember : this.$data.frontMember;
        member.$remove(idx);
        return this;
      },
      moveUpIdol: function(idx, reverse, isSupport) {
        var member, tmp;
        member = isSupport ? this.$data.supportMember : this.$data.frontMember;
        tmp = member.$remove(idx);
        member.splice(idx + (reverse ? 1 : -1), 0, tmp);
        return this;
      },
      calc: function() {
        var baseAP, baseDP, detail, eff, front, i, idol, idol_i, idol_j, incByRenkeiAP, incByRenkeiDP, incByRoungeAP, incByRoungeDP, j, obj, ren, shinai, sumAud, sumAudTmp, sumFes, sumFesTmpAP, sumFesTmpDP, sumOfRenkeiAP, sumOfRenkeiDP, support, supportAudTmp, val, _ref, _ref1, _ref2, _ref3, _ref4, _ref5, _ref6, _ref7, _ref8, _ref9;
        front = [];
        support = [];
        _ref = this.$data.frontMember;
        for (i in _ref) {
          idol = _ref[i];
          shinai = 0;
          if (100 <= parseInt(idol.shinai)) {
            shinai = 0.05;
          }
          if (200 <= parseInt(idol.shinai)) {
            shinai = 0.06;
          }
          if (300 <= parseInt(idol.shinai)) {
            shinai = 0.07;
          }
          if (400 <= parseInt(idol.shinai)) {
            shinai = 0.0775;
          }
          if (500 <= parseInt(idol.shinai)) {
            shinai = 0.0825;
          }
          baseAP = parseInt(idol.ap) + Math.ceil((parseInt(idol.ap) * shinai).toFixed(4));
          baseDP = parseInt(idol.dp) + Math.ceil((parseInt(idol.dp) * shinai).toFixed(4));
          incByRoungeAP = Math.floor(baseAP * parseFloat(this.$data.roungeBonus.ap));
          incByRoungeDP = Math.floor(baseDP * parseFloat(this.$data.roungeBonus.dp));
          incByRenkeiAP = [0, 0, 0];
          incByRenkeiDP = [0, 0, 0];
          _ref1 = this.$data.renkei;
          for (j in _ref1) {
            ren = _ref1[j];
            if (idol["renkei_" + j]) {
              incByRenkeiAP[j] += Math.floor(baseAP * parseFloat(ren.ap));
              incByRenkeiDP[j] += Math.floor(baseDP * parseFloat(ren.dp));
            }
          }
          sumOfRenkeiAP = incByRenkeiAP.reduce(function(a, b) {
            return a + b;
          });
          sumOfRenkeiDP = incByRenkeiDP.reduce(function(a, b) {
            return a + b;
          });
          front[i] = {
            name: idol.name,
            orgAP: idol.ap,
            orgDP: idol.dp,
            shinaiBonusAP: Math.ceil((parseInt(idol.ap) * shinai).toFixed(4)),
            shinaiBonusDP: Math.ceil((parseInt(idol.dp) * shinai).toFixed(4)),
            baseAP: baseAP,
            baseDP: baseDP,
            incByRoungeAP: incByRoungeAP,
            incByRoungeDP: incByRoungeDP,
            incByRenkeiAP: incByRenkeiAP,
            incByRenkeiDP: incByRenkeiDP,
            incBySkillAP: [],
            incBySkillDP: [],
            sumOfRenkeiAP: sumOfRenkeiAP,
            sumOfRenkeiDP: sumOfRenkeiDP,
            sumOfSkillAP: 0,
            sumOfSkillDP: 0
          };
        }
        _ref2 = this.$data.frontMember;
        for (i in _ref2) {
          idol_i = _ref2[i];
          eff = getEffect(idol_i.skill_serialized, idol_i.skill_level);
          if (!idol_i.skill_activated) {
            continue;
          }
          _ref3 = this.$data.frontMember;
          for (j in _ref3) {
            idol_j = _ref3[j];
            if (eff.target == null) {
              continue;
            }
            if (__indexOf.call(eff.target, "self") >= 0 && i !== j) {
              continue;
            }
            if (_ref4 = idol_j.region, __indexOf.call(eff.target, _ref4) < 0) {
              continue;
            }
            front[j].incBySkillAP.push([eff, Math.floor(front[j].baseAP * eff.ap)]);
            front[j].incBySkillDP.push([eff, Math.floor(front[j].baseDP * eff.dp)]);
            front[j].sumOfSkillAP += Math.floor(front[j].baseAP * eff.ap);
            front[j].sumOfSkillDP += Math.floor(front[j].baseDP * eff.dp);
          }
        }
        _ref5 = this.$data.supportMember;
        for (i in _ref5) {
          idol = _ref5[i];
          support[i] = {
            name: idol.name,
            ap: Math.floor(parseInt(idol.ap) * 0.8),
            dp: Math.floor(parseInt(idol.dp) * 0.8)
          };
        }
        this.$data.result.front = front;
        this.$data.result.support = support;
        detail = "";
        detail += "-- フロントメンバー\n";
        sumAud = 0;
        sumFes = 0;
        for (i in front) {
          obj = front[i];
          sumAudTmp = 0;
          sumAudTmp += obj.baseAP;
          sumAudTmp += obj.baseDP;
          sumAudTmp += obj.incByRoungeAP;
          sumAudTmp += obj.incByRoungeDP;
          sumAudTmp += obj.sumOfRenkeiAP;
          sumAudTmp += obj.sumOfRenkeiDP;
          sumAudTmp += obj.sumOfSkillAP;
          sumAudTmp += obj.sumOfSkillDP;
          sumAud += sumAudTmp;
          sumFesTmpAP = 0;
          sumFesTmpAP += obj.baseAP;
          sumFesTmpAP += obj.incByRoungeAP;
          sumFesTmpAP += obj.sumOfRenkeiAP;
          sumFesTmpAP += obj.sumOfSkillAP;
          sumFes += sumFesTmpAP;
          sumFesTmpDP = 0;
          sumFesTmpDP += obj.baseDP;
          sumFesTmpDP += obj.incByRoungeDP;
          sumFesTmpDP += obj.sumOfRenkeiDP;
          sumFesTmpDP += obj.sumOfSkillDP;
          detail += "[" + (parseInt(i) + 1) + "] " + obj.name + "\n";
          detail += "  計算基本AP: " + obj.baseAP + "\n";
          detail += "    基礎: " + obj.orgAP + " + 親愛: " + obj.shinaiBonusAP + "\n";
          detail += "  連携スキル増加分: " + obj.sumOfRenkeiAP + "\n";
          _ref6 = obj.incByRenkeiAP;
          for (j in _ref6) {
            val = _ref6[j];
            if (0 < val) {
              detail += "    + 連携スキル" + (parseInt(j) + 1) + " x" + (parseFloat(this.$data.renkei[j].ap).toFixed(2)) + ": " + val + "\n";
            }
          }
          detail += "  固有スキル増加分: " + obj.sumOfSkillAP + "\n";
          _ref7 = obj.incBySkillAP;
          for (j in _ref7) {
            val = _ref7[j];
            detail += "    + " + val[0].target + " x" + (parseFloat(val[0].ap).toFixed(3)) + ": " + val[1] + "\n";
          }
          detail += "  ラウンジボーナスAP: " + obj.incByRoungeAP + "\n";
          detail += "  計算基本DP: " + obj.baseDP + "\n";
          detail += "    基礎: " + obj.orgDP + " + 親愛: " + obj.shinaiBonusDP + "\n";
          detail += "  連携スキル増加分: " + obj.sumOfRenkeiDP + "\n";
          _ref8 = obj.incByRenkeiDP;
          for (j in _ref8) {
            val = _ref8[j];
            if (0 < val) {
              detail += "    + 連携スキル" + (parseInt(j) + 1) + " x" + (parseFloat(this.$data.renkei[j].dp).toFixed(2)) + ": " + val + "\n";
            }
          }
          detail += "  固有スキル増加分: " + obj.sumOfSkillDP + "\n";
          _ref9 = obj.incBySkillDP;
          for (j in _ref9) {
            val = _ref9[j];
            detail += "    + " + val[0].target + " x" + (parseFloat(val[0].dp).toFixed(3)) + ": " + val[1] + "\n";
          }
          detail += "  ラウンジボーナスDP: " + obj.incByRoungeDP + "\n";
          detail += "-> 合同フェス発揮基準値: " + sumFesTmpAP + "\n";
          detail += "-> 合同フェス耐久基準値: " + sumFesTmpDP + "\n";
          detail += "-> オーディションバトル発揮値: " + sumAudTmp + "\n";
          detail += "  -----  -----  -----  -----  \n";
        }
        detail += "\n-- サポートメンバー\n";
        supportAudTmp = 0;
        for (i in support) {
          obj = support[i];
          sumAudTmp = 0;
          sumAudTmp += obj.ap;
          sumAudTmp += obj.dp;
          supportAudTmp += sumAudTmp;
          sumAud += sumAudTmp;
          detail += "" + obj.name + ": " + obj.ap + " + " + obj.dp + " = " + sumAudTmp + "\n";
        }
        detail += "サポートメンバー総合値: " + supportAudTmp + "\n";
        detail += "\n\n";
        detail += "合同フェス発揮基準値（総合）: " + sumFes + "\n";
        detail += "オーディションバトル発揮値（総合）: " + sumAud + "\n";
        detail += "合同フェス先制アピール参考値\n";
        detail += "BP1: normal->" + ((parseInt(sumFes) / 12).toFixed(1)) + ", nice->" + ((parseInt(sumFes) / 6).toFixed(1)) + ", perfect->" + ((parseInt(sumFes) / 2).toFixed(1)) + "\n";
        detail += "BP2: normal->" + ((parseInt(sumFes) / 20).toFixed(1)) + ", nice->" + ((parseInt(sumFes) / 10).toFixed(1)) + ", perfect->" + ((parseInt(sumFes) * 3 / 10).toFixed(1)) + "\n";
        detail += "BP3: normal->" + ((parseInt(sumFes) / 24).toFixed(1)) + ", nice->" + ((parseInt(sumFes) / 12).toFixed(1)) + ", perfect->" + ((parseInt(sumFes) / 4).toFixed(1)) + "\n";
        this.$data.result.sumAud = sumAud;
        this.$data.result.sumAudInIMC = Math.ceil(sumAud * 1.1);
        this.$data.result.sumFes = sumFes;
        return this.$data.result.detail = detail;
      }
    }
  });
});

--Bilighteral Balance
Duel.LoadScript("bilightutility.lua")
local s,id=GetID()
function s.initial_effect(c)
	--Act in za hando and on za fieldo
	Bilighteral.CreateActivation(c)
	--Spell Effect
	local fusiontab={fusfilter=s.fusfilter,matfilter=s.matfilter,stage2=s.fstage2}
	local ritualtab={filter=s.ritfilter,matfilter=s.matfilter,stage2=s.rstage2}
	local rittg=Ritual.Target(ritualtab)
	local fustg=Fusion.SummonEffTG(fusiontab)
	local e2=Bilighteral.AddSpellEffect({handler=c,cat=CATEGORY_SPECIAL_SUMMON,tg=s.spelltg(rittg,fustg),op=s.spellop(rittg,Ritual.Operation(ritualtab),fustg,Fusion.SummonEffOP(fusiontab))})
	c:RegisterEffect(e2)
	--Trap Effect
	local e3=Bilighteral.AddTrapEffect({handler=c,cat=CATEGORY_SPECIAL_SUMMON,prop=EFFECT_FLAG_CARD_TARGET,con=s.trapcon,tg=s.traptg,op=s.trapop})
	c:RegisterEffect(e3)
	--Custom Event
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e4:SetCode(EVENT_CHAIN_END)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCondition(s.evcon)
	e4:SetOperation(s.evop)
	c:RegisterEffect(e4)
	e2:SetLabelObject(e4)
	--Stuff after Summon
	local e5=Effect.CreateEffect(c)
	e5:SetCategory(CATEGORY_TOHAND)
	e5:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e5:SetCode(EVENT_CUSTOM+id)
	e5:SetRange(LOCATION_GRAVE)
	e5:SetCondition(s.con)
	e5:SetCost(s.cost)
	e5:SetTarget(s.tg)
	e5:SetOperation(s.op)
	c:RegisterEffect(e5)
end

--Spell Effect

function s.ritfilter(c)
	return c:IsRitualMonster() --and c:IsSetCard(0x400)
end

function s.fusfilter(c)
	return c:IsType(TYPE_FUSION) --and c:IsSetCard(0x400)
end

function s.matfilter(c)
	return c:GetAttribute()&ATTRIBUTE_LIGHT==ATTRIBUTE_LIGHT or c:GetAttribute()&ATTRIBUTE_DARK==ATTRIBUTE_DARK
end

function s.spelltg(rittg,fustg)
	return function(e,tp,eg,ep,ev,re,r,rp,chk)
		if chk==0 then return (rittg(e,tp,eg,ep,ev,re,r,rp,0) or fustg(e,tp,eg,ep,ev,re,r,rp,0)) and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 end
		local additional=0
		if Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_SYNCHRO) and Duel.IsExistingMatchingCard(Card.IsType,tp,LOCATION_MZONE,0,1,nil,TYPE_XYZ) then
			additional=1
		end
		e:SetLabel(additional)
	end
end

function s.spellop(rittg,ritop,fustg,fusop)
	return function(e,tp,eg,ep,ev,re,r,rp)
		if Duel.GetLocationCount(tp,LOCATION_MZONE)==0 then return end
		local additional,choice=e:GetLabel(),-1
		if rittg(e,tp,eg,ep,ev,re,r,rp,0) and fustg(e,tp,eg,ep,ev,re,r,rp,0) then
			choice=Duel.SelectOption(tp,aux.Stringid(id,6),aux.Stringid(id,7))
			elseif rittg(e,tp,eg,ep,ev,re,r,rp,0) then
				choice=Duel.SelectOption(tp,aux.Stringid(id,6))
				elseif fustg(e,tp,eg,ep,ev,re,r,rp,0) then
					choice=Duel.SelectOption(tp,aux.Stringid(id,7))+1
					else return
		end
		if choice==0 then
			ritop(e,tp,eg,ep,ev,re,r,rp)
			elseif choice==1 then
			fusop(e,tp,eg,ep,ev,re,r,rp)
			else return
		end
		if choice==0 and additional==1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,8)) then
			fusop(e,tp,eg,ep,ev,re,r,rp)
			elseif choice==1 and additional==1 and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.SelectYesNo(tp,aux.Stringid(id,8)) then
				ritop(e,tp,eg,ep,ev,re,r,rp)
				else return
		end
	end
end

function s.rstage2(mg,e,tp,eg,ep,ev,re,r,rp,tc)
	if e:GetLabelObject():GetLabelObject() then
		e:GetLabelObject():SetLabelObject(e:GetLabelObject():GetLabelObject()+Group.FromCards(tc))
		else e:GetLabelObject():SetLabelObject(Group.FromCards(tc))
	end
	e:GetLabelObject():GetLabelObject():KeepAlive()
end

function s.fstage2(e,tc,tp,sg,chk)
	if chk==1 then
		if e:GetLabelObject():GetLabelObject() then
			e:GetLabelObject():SetLabelObject(e:GetLabelObject():GetLabelObject()+Group.FromCards(tc))
			else e:GetLabelObject():SetLabelObject(Group.FromCards(tc))
		end
		e:GetLabelObject():GetLabelObject():KeepAlive()
	end
end

--Custom Event

function s.evcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetLabelObject()
end

function s.evop(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	Duel.RaiseEvent(tc,EVENT_CUSTOM+id,e,0,tp,tp,0)
	e:SetLabelObject(nil)
end

--Stuff after Summon

function s.con(e,tp,eg,ep,ev,re,r,rp)
	return re:GetHandler()==e:GetHandler()
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsLocation(LOCATION_GRAVE) and e:GetHandler():IsAbleToRemove() end
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_COST)
end

function s.spfilter(c,e,tp)
	return c:IsLocation(LOCATION_DECK) and c:IsCanBeSpecialSummoned(e,0,tp,false,false) -- and c:IsSetCard(0x400)
end

function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local mat=Group.CreateGroup()
	for tc in aux.Next(eg) do
		mat:Merge(tc:GetMaterial())
	end
	local l,d,choice,additional=false,false,-1,0
	if mat:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_LIGHT) then l=true end
	if mat:IsExists(Card.IsAttribute,1,nil,ATTRIBUTE_DARK) then d=true end
	local l2,d2=(l==true and Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK,0,1,nil,e,tp)),(d==true and Duel.IsExistingTarget(aux.TRUE,tp,0,LOCATION_ONFIELD,1,nil))
	if chk==0 then return l2 or d2 end
	if l2 and d2 then
			choice=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
			elseif l2 then
				choice=Duel.SelectOption(tp,aux.Stringid(id,2))
				elseif d2 then
					choice=Duel.SelectOption(tp,aux.Stringid(id,3))+1
					else return
	end
	if Duel.SelectYesNo(tp,aux.Stringid(id,4)) then additional=1 end
	if choice==0 then 
		local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
		Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,tp,LOCATION_DECK)
		e:SetLabelObject(tc)
		tc:KeepAlive()
		if additional==1 then
			local tc=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,#mat,nil)
			Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,#tc,1-tp,LOCATION_ONFIELD)
			Duel.SetTargetCard(tc)
		end
		elseif choice==1 then
			if additional==1 then
				local tc=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp)
				Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,tc,1,tp,LOCATION_DECK)
				e:SetLabelObject(tc)
				tc:KeepAlive()
			end
			local tc=Duel.SelectMatchingCard(tp,aux.TRUE,tp,0,LOCATION_ONFIELD,1,#mat,nil)
			Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,#tc,1-tp,LOCATION_ONFIELD)
			Duel.SetTargetCard(tc)
			else return
	end
	e:SetLabel(choice,additional)
end

function s.op(e,tp,eg,ep,ev,re,r,rp)
	local choice,additional=e:GetLabel()
	if choice==0 and additional==1 then
		local tc=e:GetLabelObject()
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
		tc=Duel.GetTargetCards(e)
		Duel.Destroy(tc,REASON_EFFECT)
		elseif choice==0 and additional==0 then
			local tc=e:GetLabelObject()
			Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
			elseif choice==1 and additional==1 then
				local tc=Duel.GetTargetCards(e)
				Duel.Destroy(tc,REASON_EFFECT)
				tc=e:GetLabelObject()
				Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
				elseif choice==1 and additional==0 then
					local tc=Duel.GetTargetCards(e)
					Duel.Destroy(tc,REASON_EFFECT)
					else return
	end
end

--Trap Effect

function s.filter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false) and (c:GetAttribute()&ATTRIBUTE_LIGHT==ATTRIBUTE_LIGHT or c:GetAttribute()&ATTRIBUTE_DARK==ATTRIBUTE_DARK)
end

function s.trapcon(e,tp,eg,ep,ev,re,r,rp)
	local l,d=Duel.GetMatchingGroupCount(Card.IsAttribute,tp,LOCATION_MZONE,0,nil,ATTRIBUTE_LIGHT),Duel.GetMatchingGroupCount(Card.IsAttribute,tp,LOCATION_MZONE,0,nil,ATTRIBUTE_DARK)
	return l~=d
end

function s.traptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	local l,d=Duel.GetMatchingGroup(Card.IsAttribute,tp,LOCATION_MZONE,0,nil,ATTRIBUTE_LIGHT),Duel.GetMatchingGroup(Card.IsAttribute,tp,LOCATION_MZONE,0,nil,ATTRIBUTE_DARK)
	local ct,g
	if #l>#d then
		ct,g=#l-#d,Duel.GetMatchingGroup(Card.IsAttribute,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,ATTRIBUTE_DARK)
		elseif #d>#l then
			ct,g=#d-#l,Duel.GetMatchingGroup(Card.IsAttribute,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil,ATTRIBUTE_LIGHT)
			else ct,g=0,nil
	end
	if chkc then return chkc:IsLocation(LOCATION_GRAVE+LOCATION_REMOVED) and s.filter(chkc,e,tp) end
	if chk==0 then return g and ct>0 and Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,ct,nil,e,tp) and Duel.GetLocationCount(tp,LOCATION_MZONE)>=ct end
	local tc=g:FilterSelect(tp,s.filter,ct,ct,nil,e,tp)
	Duel.SetTargetCard(tc)
	tc:KeepAlive()
	e:SetLabel(ct)
end

function s.trapop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	local ct=e:GetLabel()
	if not g or Duel.GetLocationCount(tp,LOCATION_MZONE)<ct then return end
	Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
end
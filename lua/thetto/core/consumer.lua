local Consumer = {}
Consumer.__index = Consumer

function Consumer.new(pipeline, consume)
  local tbl = {
    _pipeline = pipeline,
    _consume = consume,
  }
  return setmetatable(tbl, Consumer)
end

function Consumer.start(self)
  return nil
end

function Consumer.consume(self, items)
  return nil
end

function Consumer.error(self, err)
  return nil
end

function Consumer.complete(self)
  return nil
end

return Consumer

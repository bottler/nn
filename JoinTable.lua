local JoinTable, parent = torch.class('nn.JoinTable', 'nn.Module')

function JoinTable:__init(dimension)
   parent.__init(self)
   self.size = torch.LongStorage()
   self.dimension = dimension
   self.gradInput = {}
   self.nInputDims = nil
end 

-- Sets the expected number of dimensions
-- in a non-minibatch input.
function JoinTable:setNumInputDims(nInputDims)
   self.nInputDims = nInputDims
   return self
end

function JoinTable:updateOutput(input) 
   local dimension = self.dimension
   if self.nInputDims and input[1]:dim()==(self.nInputDims+1) then
       dimension = dimension + 1
   end

   for i=1,#input do
      local currentOutput = input[i]
      if i == 1 then
         self.size:resize(currentOutput:dim()):copy(currentOutput:size())
      else
         self.size[dimension] = self.size[dimension]
            + currentOutput:size(dimension)
      end 
   end
   self.output:resize(self.size)
   
   local offset = 1  
   for i=1,#input do
      local currentOutput = input[i]
      self.output:narrow(dimension, offset,
         currentOutput:size(dimension)):copy(currentOutput)
      offset = offset + currentOutput:size(dimension)
   end
   return self.output

end

function JoinTable:updateGradInput(input, gradOutput)
   local dimension = self.dimension
   if self.nInputDims and input[1]:dim()==(self.nInputDims+1) then
       dimension = dimension + 1
   end

   for i=1,#input do 
      if self.gradInput[i] == nil then
         self.gradInput[i] = input[i].new()
      end
      self.gradInput[i]:resizeAs(input[i])
   end

   local offset = 1
   for i=1,#input do
      local currentOutput = input[i] 
      local currentGradInput = gradOutput:narrow(dimension, offset,
                      currentOutput:size(dimension))
      self.gradInput[i]:copy(currentGradInput)
      offset = offset + currentOutput:size(dimension)
   end
   return self.gradInput
end

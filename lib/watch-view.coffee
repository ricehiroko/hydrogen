{TextEditorView} = require 'atom-space-pen-views'
_ = require 'lodash'

ResultView = require './result-view'

module.exports =
class WatchView

    constructor: (@kernel, @grammar) ->
        @element = document.createElement('div')
        @element.classList.add('hydrogen', 'watch-view')

        @inputElement = new TextEditorView()
        @inputElement.element.classList.add('watch-input')

        @inputEditor = @inputElement.getModel()
        @inputEditor.setGrammar(@grammar)
        @inputEditor.setSoftWrapped(true)
        @inputEditor.setLineNumberGutterVisible(false)
        @inputEditor.moveToTop()

        @resultView = new ResultView()
        @resultView.setMultiline(true)

        @element.appendChild(@inputElement.element)
        @element.appendChild(@resultView.element)

        @addHistoryScrollbar().clearHistory()

    clearHistory: (@currentHistory=[]) -> this
    addToHistory: (result) ->
      return if result.data is 'ok'
      @currentHistory.push(result)
      @historyScrollbar.querySelector('.hidden').style.width =
        (total = @currentHistory.length * @historyScrollbar.offsetWidth) + 'px'
      @historyScrollbar.scrollLeft = total
      this

    addHistoryScrollbar: ->
        @historyScrollbar = document.createElement 'div'
        filler = document.createElement 'div'
        @historyScrollbar.classList.add 'history-scrollbar'
        filler.classList.add 'hidden'
        @historyScrollbar.appendChild filler
        @historyScrollbar.onscroll = do (currentPos=0) => (e) =>
            pos = Math.ceil(@historyScrollbar.scrollLeft / (@historyScrollbar.offsetWidth+1))
            pos = @currentHistory.length - 1 if pos >= @currentHistory.length
            if currentPos != pos
              @clearResults()
              @resultView.addResult @currentHistory[currentPos = pos]

        @element.appendChild @historyScrollbar
        this

    run: ->
        code = @getCode()
        @clearResults()
        console.log "watchview running:", code
        if code? and code.length? and code.length > 0
            @kernel.executeWatch code, (result) =>
                console.log "watchview got result:", result
                @resultView.addResult(result)
                @addToHistory result

    setCode: (code)->
      @inputEditor.setText code
      this

    getCode: ->
        return @inputElement.getText()

    clearResults: ->
        try
            @element.removeChild(@resultView.element)
            @resultView.destroy()
        catch e
            console.error e

        @resultView = new ResultView()
        @resultView.setMultiline(true)
        @element.appendChild(@resultView.element)

    destroy: ->
      @clearResults()
      @element.parentNode.removeChild @element

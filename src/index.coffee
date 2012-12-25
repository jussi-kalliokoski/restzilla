express = require 'express'
jsdom = require 'jsdom'

getTime = (str) -> +new Date(str.trim().replace(/-/g, '/'))

module.exports = (config) ->

  BASE_URL = config.baseURL
  JQUERY = [config.jqueryURL || "http://code.jquery.com/jquery.js"]

  app = express()

  app.get '/', (req, res, next) ->
    url = BASE_URL + 'describecomponents.cgi'

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if (e)

      $ = window.$
      ret = []

      $('#bugzilla-body tr').each ->
        $p = $(@)

        ret.push
          name:         $('th a', $p).text().trim()
          description:  $('td', $p).text().trim()

      res.send ret

  app.get '/:product', (req, res, next) ->
    url = BASE_URL + 'describecomponents.cgi?product=' + req.params.product

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if (e)

      $ = window.$
      ret = []

      $('.component_table tbody tr').each ->
        $c = $(@)
        name = $('.component_name a', $c).text().trim()

        if name
          ret.push
            name: name

      res.send ret

  app.get '/:product/:component', (req, res, next) ->
    url = BASE_URL + 'buglist.cgi'
    url += '?product=' + req.params.product
    url += '&component=' + req.params.component

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if e

      $ = window.$
      ret = []

      $('.bz_buglist tr').each ->
        id = @id.substr(1)
        if id
          ret.push id

      res.send(ret)

  app.get '/:product/:component/:bug', (req, res, next) ->
    url = BASE_URL + 'show_bug.cgi?id=' + req.params.bug

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if e

      $ = window.$

      res.send
        number:     req.params.bug
        title:      $('#short_desc_nonedit_display').text()
        body:       $('.bz_first_comment .bz_comment_text').text().trim()
        created_at: getTime($('.bz_first_comment_head .bz_comment_time').text())
        product:    $('#field_container_product').text()
        component:  $('#field_container_component').text()
        reporter:   $('.bz_first_comment_head .bz_comment_user .fn').text()
        assignee:   $('.fn', $('td.field_label a[href="page.cgi?id=fields.html#assigned_to"]').parent().parent().next()).text()
        milestone:  $('td.field_label a[href="page.cgi?id=fields.html#target_milestone"]').parent().parent().next().text().trim()
        status:     $('#bz_field_status').text().trim().replace(/\s+/g, ' ')
        comments:   $('.bz_comment').length - 1

  app.get '/:product/:component/:bug/comments', (req, res, next) ->
    url = BASE_URL + 'show_bug.cgi?id=' + req.params.bug

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if e

      $ = window.$
      ret = []

      $('.bz_comment').each (i) ->
        if not i
          return

        $c = $(@)

        ret.push
          number:     i - 1
          created_at: getTime($('.bz_comment_time', $c).text())
          user:       $('.bz_comment_head .bz_comment_user .fn', $c).text()
          body:       $('.bz_comment_text', $c).text().trim()

      res.send ret

  app.get '/:product/:component/:bug/comments/:comment', (req, res, next) ->
    url = BASE_URL + 'show_bug.cgi?id=' + req.params.bug

    jsdom.env url, JQUERY, (e, window) ->
      return next(e) if e

      $ = window.$
      $c = $('#c' + req.params.comment)

      res.send
        number:     req.params.comment
        created_at: getTime($('.bz_comment_time', $c).text())
        user:       $('.bz_comment_head .bz_comment_user .fn', $c).text()
        body:       $('.bz_comment_text', $c).text().trim()

  return app
